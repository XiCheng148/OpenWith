import SwiftUI

struct AppListView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var showingSortMenu = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏和排序按钮
            HStack {
                SearchBar(text: $viewModel.searchText)
                
                Menu {
                    ForEach(ContentViewModel.AppSortOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.setSortOption(option)
                        } label: {
                            Label(option.rawValue, systemImage: getSortIcon(for: option))
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .foregroundColor(.secondary)
                        .imageScale(.large)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 30)
            }
            .padding()
            
            // 应用列表
            List(viewModel.sortedApps) { app in
                AppListItem(
                    app: app,
                    isSelected: app.id == viewModel.selectedApp?.id
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(app.id == viewModel.selectedApp?.id ? Color.accentColor.opacity(0.1) : Color.clear)
                        .padding(.horizontal, 4)
                )
                .onTapGesture {
                    Task {
                        await viewModel.selectApp(app)
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }
    
    private func getSortIcon(for option: ContentViewModel.AppSortOption) -> String {
        switch option {
        case .name:
            return "textformat"
        case .associatedCount:
            return "number.circle"
        case .recentUsed:
            return "clock"
        }
    }
}

// 搜索框组件
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索应用", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.textBackgroundColor))
        }
    }
}

// 应用列表项组件
struct AppListItem: View {
    let app: AppInfo
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 应用图标
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // 应用名称
                Text(app.name)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .accentColor : .primary)
                
                // Bundle ID
                Text(app.id)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 文件类型数量
            if !app.associatedFileTypes.isEmpty {
                Text("\(app.associatedFileTypes.count)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        Capsule()
                            .fill(Color(.separatorColor).opacity(0.5))
                    }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 0)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
} 
