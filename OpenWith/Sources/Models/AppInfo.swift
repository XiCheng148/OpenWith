import Foundation
import AppKit

struct AppInfo: Identifiable, Hashable {
    let id: String // Bundle ID
    let name: String
    let path: URL
    let icon: NSImage?
    
    // 关联的文件类型
    var associatedFileTypes: Set<FileTypeInfo>
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.id == rhs.id
    }
} 