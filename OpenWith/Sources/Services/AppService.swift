import Foundation
import AppKit
import UniformTypeIdentifiers

protocol AppServiceProtocol {
    func getAllInstalledApps() async throws -> [AppInfo]
    func getAppInfo(for bundleId: String) async throws -> AppInfo?
    func searchApps(keyword: String) async throws -> [AppInfo]
}

class AppService: AppServiceProtocol {
    private let workspace = NSWorkspace.shared
    private let fileTypeService: FileTypeServiceProtocol
    
    init(fileTypeService: FileTypeServiceProtocol = FileTypeService()) {
        self.fileTypeService = fileTypeService
    }
    
    func getAllInstalledApps() async throws -> [AppInfo] {
        // 获取应用程序目录下的所有应用
        let appsDirectory = try FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: "/Applications"),
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        
        return try await withThrowingTaskGroup(of: AppInfo?.self) { group in
            for appURL in appsDirectory where appURL.pathExtension == "app" {
                group.addTask {
                    try await self.createAppInfo(from: appURL)
                }
            }
            
            var apps: [AppInfo] = []
            for try await app in group {
                if let app = app {
                    apps.append(app)
                }
            }
            
            return apps.sorted { $0.name < $1.name }
        }
    }
    
    private func createAppInfo(from url: URL) async throws -> AppInfo? {
        guard let bundle = Bundle(url: url),
              let bundleId = bundle.bundleIdentifier,
              let name = bundle.infoDictionary?["CFBundleName"] as? String else {
            return nil
        }
        
        let icon = workspace.icon(forFile: url.path)
        
        // 获取应用支持的文件类型
        let associatedFileTypes = try await getAssociatedFileTypes(for: bundleId)
        
        return AppInfo(
            id: bundleId,
            name: name,
            path: url,
            icon: icon,
            associatedFileTypes: associatedFileTypes
        )
    }
    
    private func getAssociatedFileTypes(for bundleId: String) async throws -> Set<FileTypeInfo> {
        var fileTypes = Set<FileTypeInfo>()
        
        // 获取所有可用的文件类型
        let allFileTypes = try await fileTypeService.getAvailableFileTypes()
        
        // 只保留当前应用作为默认处理程序的文件类型
        for fileType in allFileTypes {
            if let defaultHandler = try await fileTypeService.getDefaultHandler(for: fileType),
               defaultHandler == bundleId {
                fileTypes.insert(fileType)
            }
        }
        
        return fileTypes
    }
    
    func searchApps(keyword: String) async throws -> [AppInfo] {
        let allApps = try await getAllInstalledApps()
        return allApps.filter { app in
            app.name.localizedCaseInsensitiveContains(keyword) ||
            app.id.localizedCaseInsensitiveContains(keyword)
        }
    }
    
    func getAppInfo(for bundleId: String) async throws -> AppInfo? {
        let allApps = try await getAllInstalledApps()
        return allApps.first { $0.id == bundleId }
    }
    
    // 其他方法实现...
} 