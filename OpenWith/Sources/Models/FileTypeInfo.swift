import Foundation
import UniformTypeIdentifiers
import AppKit

struct FileTypeInfo: Identifiable, Hashable {
    let id: String // 使用扩展名作为 id
    let fileExtension: String
    let icon: NSImage?
    let utType: UTType
    
    // 默认打开方式的应用程序 Bundle ID
    var defaultHandler: String?
    
    // 新增：相关的文件扩展名
    let relatedExtensions: [String]
    
    var displayName: String {
        if relatedExtensions.isEmpty {
            return ".\(fileExtension)"
        } else {
            // 将主扩展名和相关扩展名合并显示,使用斜杠分隔
            let allExtensions = [fileExtension] + relatedExtensions
            return allExtensions.map { "." + $0 }.joined(separator: "/")
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FileTypeInfo, rhs: FileTypeInfo) -> Bool {
        lhs.id == rhs.id
    }
} 