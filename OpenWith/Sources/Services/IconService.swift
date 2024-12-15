import AppKit
import UniformTypeIdentifiers

class IconService {
    static let shared = IconService()
    
    func getIcon(for fileExtension: String) -> NSImage? {
        // 使用系统通用文件图标，不带应用标识
        return NSImage(systemSymbolName: "doc.fill", accessibilityDescription: fileExtension)?
            .withSymbolConfiguration(.init(scale: .large))
    }
} 