import SwiftUI

struct AddFileTypeSheet: View {
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.dismiss) private var dismiss
    let onAdd: (Set<FileTypeInfo>) -> Void
    
    @State private var selectedFileTypes: Set<FileTypeInfo> = []
    @State private var searchText = ""
    
    // 定义分类
    private let categories = [
        "常用": ["txt", "pdf", "jpg", "png", "doc", "docx", "mp3", "mp4"],
        "文档": ["txt", "rtf", "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "epub"],
        "图片": ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic", "svg", "icns"],
        "音视频": ["mp3", "mp4", "mov", "avi", "wav", "aiff", "midi"],
        "开发": ["swift", "c", "cpp", "h", "hpp", "m", "mm", "py", "java", "js", "json", "yaml", "xml", "plist", "sh"],
        "压缩": ["zip", "gz", "bz2", "7z", "rar"],
        "其他": ["app", "dmg", "iso", "db", "log", "font"]
    ]
    
    // 添加分类标题和图标
    private let categoryIcons = [
        "常用": "star.fill",
        "文档": "doc.fill",
        "图片": "photo.fill",
        "音视频": "play.circle.fill",
        "开发": "chevron.left.forwardslash.chevron.right",
        "压缩": "archivebox.fill",
        "其他": "ellipsis.circle.fill"
    ]
    
    var filteredFileTypes: [String: [FileTypeInfo]] {
        // 获取当前应用已关联的文件类型
        let associatedExtensions = viewModel.selectedApp?.associatedFileTypes.map { $0.fileExtension.lowercased() } ?? []
        
        if searchText.isEmpty {
            // 按分类组织文件类型，并过滤掉已关联的类型
            var result: [String: [FileTypeInfo]] = [:]
            for (category, extensions) in categories {
                let types = viewModel.filteredFileTypes.filter { fileType in
                    extensions.contains(fileType.fileExtension.lowercased()) &&
                    !associatedExtensions.contains(fileType.fileExtension.lowercased())
                }
                if !types.isEmpty {
                    result[category] = types
                }
            }
            return result
        } else {
            // 搜索时只显示匹配的文件类型，同时过滤掉已关联的类型
            let filtered = viewModel.filteredFileTypes.filter { fileType in
                !associatedExtensions.contains(fileType.fileExtension.lowercased()) &&
                (fileType.displayName.localizedCaseInsensitiveContains(searchText) ||
                 fileType.fileExtension.localizedCaseInsensitiveContains(searchText))
            }
            return filtered.isEmpty ? [:] : ["搜索结果": filtered]
        }
    }
    
    // 添加清除选择按钮
    private var clearButton: some View {
        Button {
            withAnimation {
                selectedFileTypes.removeAll()
            }
        } label: {
            Text("清除选择")
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .disabled(selectedFileTypes.isEmpty)
    }
    
    // 添加滚动视图的引用
    @Namespace private var namespace
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("添加文件类型")
                    .font(.headline)
                Spacer()
                
                // 清除按钮
                if !selectedFileTypes.isEmpty {
                    Divider()
                        .frame(height: 12)
                        .padding(.horizontal, 8)
                    clearButton
                }
            }
            .padding()
            .background(.bar)
            
            // 搜索栏和已选计数
            HStack {
                SearchBar(text: $searchText)
                
                if !selectedFileTypes.isEmpty {
                    Text("\(selectedFileTypes.count) 个已选择")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(Color(.separatorColor))
                        }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // 文件类型列表
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(filteredFileTypes.keys.sorted()), id: \.self) { category in
                            if let types = filteredFileTypes[category] {
                                VStack(alignment: .leading, spacing: 8) {
                                    // 分类标题
                                    HStack(spacing: 6) {
                                        Image(systemName: categoryIcons[category] ?? "folder.fill")
                                            .foregroundColor(.secondary)
                                            .imageScale(.small)
                                        Text(category)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.secondary)
                                        
                                        if let count = filteredFileTypes[category]?.count {
                                            Text("\(count)")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background {
                                                    Capsule()
                                                        .fill(Color(.separatorColor))
                                                }
                                        }
                                    }
                                    .id(category) // 添加 id 用于跳转
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                    
                                    // 文件类型网格
                                    LazyVGrid(columns: [
                                        GridItem(.adaptive(minimum: 80, maximum: 80), spacing: 12)
                                    ], spacing: 12) {
                                        ForEach(types) { fileType in
                                            FileTypeSelectionItem(
                                                fileType: fileType,
                                                isSelected: selectedFileTypes.contains(fileType)
                                            )
                                            .onTapGesture {
                                                withAnimation(.spring(response: 0.2)) {
                                                    if selectedFileTypes.contains(fileType) {
                                                        selectedFileTypes.remove(fileType)
                                                    } else {
                                                        selectedFileTypes.insert(fileType)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                    .onAppear {
                        scrollProxy = proxy
                    }
                }
            }
            
            Divider()
            
            // 底部工具栏
            HStack {
                Button("取消", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("全选") {
                    withAnimation {
                        selectedFileTypes = Set(filteredFileTypes.values.flatMap { $0 })
                    }
                }
                .disabled(filteredFileTypes.isEmpty)
                
                Button("添加") {
                    onAdd(selectedFileTypes)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(selectedFileTypes.isEmpty)
            }
            .padding(12)
            .background(.bar)
        }
        .frame(minWidth: 580, minHeight: 480)
    }
}

// 文件类型选择项组件
struct FileTypeSelectionItem: View {
    let fileType: FileTypeInfo
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 图标容器
            ZStack {
                // 图标
                if let icon = fileType.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                }
                
                // 选中指示器
                if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 16, height: 16)
                        .overlay {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 16, y: -16) // 调整选中标记的位置
                }
            }
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.textBackgroundColor))
            }
            
            // 扩展名容器
            VStack(spacing: 2) {
                // 主扩展名
                Text(".\(fileType.fileExtension)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // 相关扩展名
                if !fileType.relatedExtensions.isEmpty {
                    Text(fileType.relatedExtensions.map { "." + $0 }.joined(separator: " "))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .frame(height: 30)
            .padding(.top, 4)
        }
        .frame(width: 80) // 减小宽度
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.windowBackgroundColor))
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentColor, lineWidth: 1.5)
                    }
                }
        }
        .contentShape(Rectangle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.2), value: isSelected)
    }
} 