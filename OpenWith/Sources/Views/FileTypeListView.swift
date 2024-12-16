import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct FileTypeListView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var showingAddSheet = false
    @State private var selectedFileTypes: Set<FileTypeInfo> = []
    @State private var isEditing = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    func showToast(_ message: String, duration: Double = 2) {
        withAnimation(.spring(response: 0.3)) {
            toastMessage = message
            showToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.spring(response: 0.3)) {
                showToast = false
            }
        }
    }
    
    private var fileTypeList: some View {
        List {
            ForEach(Array(viewModel.selectedApp?.associatedFileTypes ?? []).sorted(by: { $0.fileExtension < $1.fileExtension })) { fileType in
                FileTypeListItem(
                    fileType: fileType,
                    app: viewModel.selectedApp!,
                    isSelected: selectedFileTypes.contains(fileType),
                    onSelect: {
                        withAnimation(.spring(response: 0.2)) {
                            if selectedFileTypes.contains(fileType) {
                                selectedFileTypes.remove(fileType)
                            } else {
                                selectedFileTypes.insert(fileType)
                            }
                        }
                    },
                    onRemove: {
                        Task {
                            showToast("正在移除文件类型...")
                            await viewModel.removeFileTypes([fileType], from: viewModel.selectedApp!)
                            showToast("已成功移除文件类型")
                        }
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.2)) {
                        if selectedFileTypes.contains(fileType) {
                            selectedFileTypes.remove(fileType)
                        } else {
                            selectedFileTypes.insert(fileType)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.windowBackgroundColor))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(.separatorColor), lineWidth: 0.5)
                        }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
        }
        .listStyle(.inset)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let app = viewModel.selectedApp {
                // 文件类型列表
                fileTypeList
                    .padding(.top, 8)
                
                Divider()
                
                // 底部操作栏
                HStack {
                    // 左侧应用名称和文件类型数量
                    HStack(spacing: 6) {
                        Text(app.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text("(\(viewModel.selectedApp?.associatedFileTypes.count ?? 0))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 右侧添加和批量操作按钮
                    HStack(spacing: 12) {
                        // 添加按钮（最常用的操作放最左边）
                        Button {
                            showingAddSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("添加文件类型")
                            }
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background {
                                Capsule()
                                    .fill(Color.accentColor)
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Capsule())
                        
                        // 全选/取消全选按钮（次要操作）
                        if !(viewModel.selectedApp?.associatedFileTypes.isEmpty ?? true) {
                            Button {
                                withAnimation(.spring(response: 0.2)) {
                                    if selectedFileTypes.count == viewModel.selectedApp?.associatedFileTypes.count {
                                        selectedFileTypes.removeAll()
                                    } else {
                                        selectedFileTypes = Set(viewModel.selectedApp?.associatedFileTypes ?? [])
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: selectedFileTypes.count == viewModel.selectedApp?.associatedFileTypes.count ? "checkmark.circle.fill" : "circle")
                                    Text(selectedFileTypes.count == viewModel.selectedApp?.associatedFileTypes.count ? "取消全选" : "全选")
                                }
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background {
                                    Capsule()
                                        .stroke(Color(.separatorColor), lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // 批量删除按钮（危险操作放最右边）
                        if !selectedFileTypes.isEmpty {
                            Button(role: .destructive) {
                                Task {
                                    showToast("正在移除文件类型...")
                                    await viewModel.removeFileTypes(selectedFileTypes, from: app)
                                    selectedFileTypes.removeAll()
                                    showToast("已成功移除文件类型")
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                    Text("移除\(selectedFileTypes.count)个")
                                }
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background {
                                    Capsule()
                                        .fill(Color.red.opacity(0.85))
                                }
                            }
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.bar)
            } else {
                ContentUnavailableView {
                    Label("选择一个应用", systemImage: "plus.app")
                } description: {
                    Text("从左侧列表选择一个应用来管理其文件类型关联")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddFileTypeSheet(viewModel: viewModel) { fileTypes in
                if let app = viewModel.selectedApp {
                    Task {
                        showToast("正在添加文件类型...")
                        await viewModel.addFileTypes(fileTypes, to: app)
                        showToast("已成功添加文件类型")
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            Toast(message: toastMessage, isShowing: showToast)
                .padding(.bottom, 60) // 确保不会被底部工具栏遮挡
        }
    }
}

// 优化文件类型列表项组件
struct FileTypeListItem: View {
    let fileType: FileTypeInfo
    let app: AppInfo
    let isSelected: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void
    
    @State private var showingConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 选择指示器
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .imageScale(.medium)
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .contentTransition(.symbolEffect(.replace))
            
            // 图标
            if let icon = fileType.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                // 主扩展名
                Text(fileType.displayName)
                    .font(.system(size: 13, weight: .medium))
                
                // UTType 描述
                Text(fileType.utType.localizedDescription ?? "")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 默认标记
            if fileType.defaultHandler == app.id {
                Label("默认", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background {
                        Capsule()
                            .fill(Color.orange.opacity(0.12))
                    }
            }
            
            // 删除按钮
            Button {
                showingConfirmation = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.medium)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)
            .confirmationDialog("确认移除", isPresented: $showingConfirmation) {
                Button("移除", role: .destructive, action: onRemove)
            } message: {
                Text("是否确认移除此文件类型关联？")
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 16)
    }
} 
