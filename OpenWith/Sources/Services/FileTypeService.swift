import Foundation
import UniformTypeIdentifiers
import AppKit
import CoreServices
import os.log

protocol FileTypeServiceProtocol {
    func getAvailableFileTypes() async throws -> [FileTypeInfo]
    func getFileTypeInfo(for utType: UTType) async throws -> [FileTypeInfo]
    func getDefaultHandler(for fileType: FileTypeInfo) async throws -> String?
    func setDefaultHandler(_ bundleId: String, for fileType: FileTypeInfo) async throws
    func removeDefaultHandler(for fileType: FileTypeInfo) async throws
}

class FileTypeService: FileTypeServiceProtocol {
    private let workspace = NSWorkspace.shared
    private let iconService = IconService.shared
    private let logger = Logger(subsystem: "io.tuist.OpenWith", category: "FileTypeService")
    
    // 常用文件类型列表
    private let commonUTTypes: [UTType] = [
        .text,
        .plainText,
        .pdf,
        .image,
        .jpeg,
        .png,
        .gif,
        .bmp,
        .tiff,
        .movie,
        .video,
        .audio,
        .mp3,
        .html,
        .xml,
        .json,
        .yaml,
        .rtf,
        .rtfd,
        .archive
    ]
    
    func getAvailableFileTypes() async throws -> [FileTypeInfo] {
        var fileTypes: [FileTypeInfo] = []
        
        // 定义所有类型，使用可选类型
        let allTypes = [
            // 1. 常用文档类型
            [
                .text,
                .plainText,
                .rtf,
                .rtfd,
                .pdf,
                .epub,
                UTType("com.microsoft.word.doc"),
                UTType("org.openxmlformats.wordprocessingml.document"),
                UTType("com.microsoft.excel.xls"),
                UTType("org.openxmlformats.spreadsheetml.sheet"),
                UTType("com.microsoft.powerpoint.ppt"),
                UTType("org.openxmlformats.presentationml.presentation")
            ] as [UTType?],
            // 2. 图像类型
            [
                .image,
                .jpeg,
                .png,
                .gif,
                .bmp,
                .tiff,
                UTType("org.webmproject.webp"),
                .heic,
                .svg,
                .icns
            ] as [UTType?],
            // 3. 音视频类型
            [
                .movie,
                .video,
                .audio,
                .mp3,
                .mpeg4Movie,
                .mpeg4Audio,
                .quickTimeMovie,
                .wav,
                .aiff,
                UTType("public.avi"),
                .midi
            ] as [UTType?],
            // 4. 开发相关类型
            [
                .sourceCode,
                .swiftSource,
                .cSource,
                .cPlusPlusSource,
                .objectiveCSource,
                .objectiveCPlusPlusSource,
                UTType("public.python-script"),
                UTType("com.netscape.javascript-source"),
                .json,
                .yaml,
                .xml,
                .propertyList,
                .shellScript
            ] as [UTType?],
            // 5. 压缩文件类型
            [
                .archive,
                .zip,
                .gzip,
                .bz2,
                UTType("org.7-zip.7-zip-archive"),
                UTType("com.rarlab.rar-archive")
            ] as [UTType?],
            // 6. 其他常用类型
            [
                .folder,
                .aliasFile,
                .bookmark,
                .database,
                .log,
                .executable,
                .diskImage,
                .font
            ] as [UTType?]
        ].joined().compactMap { $0 }
        
        // 获取每个类型的信息
        for utType in allTypes {
            if let typeInfos = try? await getFileTypeInfo(for: utType) {
                fileTypes.append(contentsOf: typeInfos.filter { newType in
                    !fileTypes.contains(where: { $0.id == newType.id })
                })
            }
        }
        
        // 获取系统中所有已注册的文件类型
        let systemTypes = UTType.types(tag: "", tagClass: .filenameExtension, conformingTo: nil)
        for utType in systemTypes {
            if let typeInfos = try? await getFileTypeInfo(for: utType) {
                fileTypes.append(contentsOf: typeInfos.filter { newType in
                    !fileTypes.contains(where: { $0.id == newType.id })
                })
            }
        }
        
        // 过滤和排序
        return fileTypes
            .filter { !$0.fileExtension.isEmpty }
            .sorted { $0.fileExtension < $1.fileExtension }
    }
    
    func getFileTypeInfo(for utType: UTType) async throws -> [FileTypeInfo] {
        let extensions = utType.tags[.filenameExtension] ?? []
        var fileTypes: [FileTypeInfo] = []
        
        // 创建扩展名到 UTType 的映射，用于合并相同类型
        var extensionToUTType: [String: UTType] = [:]
        
        // 为每个扩展名获取其专属的 UTType
        for ext in extensions {
            guard let specificUTType = UTType(filenameExtension: ext) else {
                logger.error("Could not find specific UTType for extension: \(ext)")
                continue
            }
            
            // 检查是否已存在相同 identifier 的 UTType
            if extensionToUTType.values.contains(where: { $0.identifier == specificUTType.identifier }) {
                // logger.info("扩展名 .\(ext) 共享相同的文件类型 (\(specificUTType.identifier))")
                continue
            }
            
            extensionToUTType[ext] = specificUTType
            
            let defaultHandler = try? await getDefaultHandler(for: specificUTType)
            
            let fileType = FileTypeInfo(
                id: ext,
                fileExtension: ext,
                icon: iconService.getIcon(for: ext),
                utType: specificUTType,
                defaultHandler: defaultHandler,
                relatedExtensions: extensions.filter { 
                    if let relatedUTType = UTType(filenameExtension: $0) {
                        return relatedUTType.identifier == specificUTType.identifier && $0 != ext
                    }
                    return false
                }
            )
            fileTypes.append(fileType)
        }
        
        return fileTypes
    }
    
    func getDefaultHandler(for fileType: FileTypeInfo) async throws -> String? {
        return try await getDefaultHandler(for: fileType.utType)
    }
    
    func setDefaultHandler(_ bundleId: String, for fileType: FileTypeInfo) async throws {
        let specificUTType = UTType(tag: fileType.fileExtension,
                                   tagClass: .filenameExtension,
                                   conformingTo: nil)
        
        if let specificUTType = specificUTType {
            logger.info("🔄 正在将扩展名 .\(fileType.fileExtension) 的默认打开程序设置为: \(bundleId)")
            
            let status = LSSetDefaultRoleHandlerForContentType(
                specificUTType.identifier as CFString,
                .all,
                bundleId as CFString
            )
            
            if status != noErr {
                logger.error("❌ 设置默认程序失败: \(status)")
                throw NSError(
                    domain: NSOSStatusErrorDomain,
                    code: Int(status),
                    userInfo: [NSLocalizedDescriptionKey: "无法设置默认打开方式"]
                )
            }
            
            logger.info("✅ 成功设置 .\(fileType.fileExtension) 的默认打开程序为: \(bundleId)")
        } else {
            logger.error("❌ 无法创建扩展名 .\(fileType.fileExtension) 的文件类型")
            throw NSError(
                domain: "FileTypeService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "无法找到对应的文件类型"]
            )
        }
    }
    
    func removeDefaultHandler(for fileType: FileTypeInfo) async throws {
        logger.info("🔄 正在移除扩展名 .\(fileType.fileExtension) 的默认打开程序")
        try await setDefaultHandler("", for: fileType)
        logger.info("✅ 已成功移除 .\(fileType.fileExtension) 的默认打开程序")
    }
    
    // MARK: - Private Methods
    
    private func getDefaultHandler(for utType: UTType) async throws -> String? {
        // logger.debug("Getting default handler for UTType: \(utType.identifier)")
        
        let handler = LSCopyDefaultRoleHandlerForContentType(
            utType.identifier as CFString,
            .all
        )?.takeRetainedValue() as String?
        
        // logger.debug("Default handler: \(handler ?? "none")")
        return handler
    }
    
    func getSupportedHandlers(for utType: UTType) async throws -> [String] {
        // 获取所有支持该类型的应用程序
        let apps = LSCopyAllRoleHandlersForContentType(
            utType.identifier as CFString,
            .all
        )?.takeRetainedValue() as? [String] ?? []
        return apps
    }
    
    // 添加新方法，用于获取单个扩展名的 FileTypeInfo
    func getFileTypeInfoForExtension(_ extension: String) async throws -> FileTypeInfo? {
        guard let utType = UTType(filenameExtension: `extension`) else {
            return nil
        }
        
        let defaultHandler = try? await getDefaultHandler(for: utType)
        
        // 获取相关扩展名
        let relatedExtensions = utType.tags[.filenameExtension]?.filter { $0 != `extension` } ?? []
        
        return FileTypeInfo(
            id: `extension`,
            fileExtension: `extension`,
            icon: iconService.getIcon(for: `extension`),
            utType: utType,
            defaultHandler: defaultHandler,
            relatedExtensions: relatedExtensions
        )
    }
} 