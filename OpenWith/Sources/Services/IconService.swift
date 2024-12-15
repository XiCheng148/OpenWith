import AppKit
import UniformTypeIdentifiers

class IconService {
    static let shared = IconService()
    
    // 文件类型分类对应的图标
    private let categoryIcons: [String: String] = [
        // 文档类型
        "txt": "doc.text.fill",
        "rtf": "doc.richtext.fill",
        "pdf": "doc.fill",
        "doc": "doc.fill",
        "docx": "doc.fill",
        "xls": "tablecells.fill",
        "xlsx": "tablecells.fill",
        "ppt": "doc.fill",
        "pptx": "doc.fill",
        "epub": "book.fill",
        
        // 图像类型
        "jpg": "photo.fill",
        "jpeg": "photo.fill",
        "png": "photo.fill",
        "gif": "photo.fill",
        "bmp": "photo.fill",
        "tiff": "photo.fill",
        "webp": "photo.fill",
        "heic": "photo.fill",
        "svg": "photo.fill",
        "icns": "photo.fill",
        
        // 音视频类型
        "mp3": "music.note",
        "mp4": "play.rectangle.fill",
        "mov": "play.rectangle.fill",
        "avi": "play.rectangle.fill",
        "wav": "music.note",
        "aiff": "music.note",
        "midi": "music.note",
        
        // 开发类型
        "swift": "chevron.left.forwardslash.chevron.right",
        "c": "chevron.left.forwardslash.chevron.right",
        "cpp": "chevron.left.forwardslash.chevron.right",
        "h": "chevron.left.forwardslash.chevron.right",
        "py": "chevron.left.forwardslash.chevron.right",
        "java": "chevron.left.forwardslash.chevron.right",
        "js": "chevron.left.forwardslash.chevron.right",
        "json": "curlybraces",
        "yaml": "curlybraces",
        "xml": "chevron.left.forwardslash.chevron.right",
        "plist": "list.bullet",
        "sh": "terminal.fill",
        
        // 压缩类型
        "zip": "archivebox.fill",
        "gz": "archivebox.fill",
        "bz2": "archivebox.fill",
        "7z": "archivebox.fill",
        "rar": "archivebox.fill",
        
        // 其他类型
        "app": "app.fill",
        "dmg": "externaldrive.fill",
        "iso": "opticaldisc.fill",
        "db": "cylinder.split.1x2.fill",
        "log": "text.alignleft",
        "font": "textformat"
    ]
    
    func getIcon(for fileExtension: String) -> NSImage? {
        let iconName = categoryIcons[fileExtension.lowercased()] ?? "doc.fill"
        return NSImage(systemSymbolName: iconName, accessibilityDescription: fileExtension)?
            .withSymbolConfiguration(.init(
                paletteColors: [.systemBlue]
            ))
    }
} 