import Foundation
import Combine
import SwiftUI

class ContentViewModel: ObservableObject {
    private let appService: AppServiceProtocol
    private let fileTypeService: FileTypeServiceProtocol
    
    @Published var apps: [AppInfo] = []
    @Published var selectedApp: AppInfo?
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var availableFileTypes: [FileTypeInfo] = []
    @Published var filteredFileTypes: [FileTypeInfo] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    enum AppSortOption: String, CaseIterable {
        case name = "按名称"
        case associatedCount = "按关联数量"
        case recentUsed = "最近使用"
    }
    
    @AppStorage("appSortOption") private var sortOption: AppSortOption = .associatedCount
    @Published private(set) var sortedApps: [AppInfo] = []
    
    init(appService: AppServiceProtocol = AppService(),
         fileTypeService: FileTypeServiceProtocol = FileTypeService()) {
        self.appService = appService
        self.fileTypeService = fileTypeService
        
        setupSearchSubscription()
        Task {
            await loadApps()
            await loadFileTypes()
        }
    }
    
    private func setupSearchSubscription() {
        Publishers.CombineLatest($apps, $searchText)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] apps, _ in
                Task { @MainActor in
                    await self?.sortApps(apps)
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func loadApps() async {
        isLoading = true
        do {
            apps = try await appService.getAllInstalledApps()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    func searchApps(_ keyword: String) async {
        guard !keyword.isEmpty else {
            await loadApps()
            return
        }
        
        isLoading = true
        do {
            apps = try await appService.searchApps(keyword: keyword)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    private func loadFileTypes() async {
        do {
            availableFileTypes = try await fileTypeService.getAvailableFileTypes()
            filteredFileTypes = availableFileTypes
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func filterFileTypes(_ keyword: String) {
        guard !keyword.isEmpty else {
            filteredFileTypes = availableFileTypes
            return
        }
        
        filteredFileTypes = availableFileTypes.filter { fileType in
            fileType.displayName.localizedCaseInsensitiveContains(keyword) ||
            fileType.fileExtension.localizedCaseInsensitiveContains(keyword)
        }
    }
    
    @MainActor
    func addFileTypes(_ fileTypes: Set<FileTypeInfo>, to app: AppInfo) async {
        guard !fileTypes.isEmpty else { return }
        
        var successTypes: [FileTypeInfo] = []
        var failedTypes: [FileTypeInfo] = []
        
        do {
            for fileType in fileTypes {
                do {
                    try await fileTypeService.setDefaultHandler(app.id, for: fileType)
                    successTypes.append(fileType)
                } catch {
                    failedTypes.append(fileType)
                }
            }
            
            // 重新加载应用信息以更新关联
            if let updatedApp = try await appService.getAppInfo(for: app.id) {
                withAnimation {
                    if let index = apps.firstIndex(where: { $0.id == app.id }) {
                        apps[index] = updatedApp
                    }
                    selectedApp = updatedApp
                }
            }
            
            // 生成结果消息
            var resultMessage = ""
            if !successTypes.isEmpty {
                let successExtensions = successTypes.map { "." + $0.fileExtension }.joined(separator: "、")
                resultMessage += "成功设置: \(successExtensions)\n"
            }
            if !failedTypes.isEmpty {
                let failedExtensions = failedTypes.map { "." + $0.fileExtension }.joined(separator: "、")
                resultMessage += "设置失败: \(failedExtensions)"
            }
            
            errorMessage = resultMessage
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func removeFileType(_ fileType: FileTypeInfo, from app: AppInfo) async {
        // 移除单个文件类型关联
        await removeFileTypes([fileType], from: app)
    }
    
    @MainActor
    func removeFileTypes(_ fileTypes: Set<FileTypeInfo>, from app: AppInfo) async {
        var successTypes: [FileTypeInfo] = []
        var failedTypes: [FileTypeInfo] = []
        
        do {
            for fileType in fileTypes {
                // 只有当前应用是默认处理程序时才移除
                if fileType.defaultHandler == app.id {
                    do {
                        try await fileTypeService.removeDefaultHandler(for: fileType)
                        successTypes.append(fileType)
                    } catch {
                        failedTypes.append(fileType)
                    }
                }
            }
            
            // 重新加载应用信息以更新关联
            if let updatedApp = try await appService.getAppInfo(for: app.id) {
                withAnimation {
                    if let index = apps.firstIndex(where: { $0.id == app.id }) {
                        apps[index] = updatedApp
                    }
                    selectedApp = updatedApp
                }
            }
            
            // 生成结果消息
            var resultMessage = ""
            if !successTypes.isEmpty {
                let successExtensions = successTypes.map { "." + $0.fileExtension }.joined(separator: "、")
                resultMessage += "成功移除: \(successExtensions)\n"
            }
            if !failedTypes.isEmpty {
                let failedExtensions = failedTypes.map { "." + $0.fileExtension }.joined(separator: "、")
                resultMessage += "移除失败: \(failedExtensions)"
            }
            
            errorMessage = resultMessage
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func selectApp(_ app: AppInfo) async {
        // 先设置选中状态
        await MainActor.run {
            self.selectedApp = app
        }
        
        // 然后异步加载详细信息
        do {
            if let updatedApp = try await appService.getAppInfo(for: app.id) {
                await MainActor.run {
                    if let index = apps.firstIndex(where: { $0.id == app.id }) {
                        apps[index] = updatedApp
                    }
                    selectedApp = updatedApp
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func setSortOption(_ option: AppSortOption) {
        sortOption = option
        Task { @MainActor in
            await sortApps(apps)
        }
    }
    
    @MainActor
    private func sortApps(_ apps: [AppInfo]) async {
        withAnimation {
            sortedApps = apps.sorted { app1, app2 in
                switch sortOption {
                case .name:
                    return app1.name.localizedStandardCompare(app2.name) == .orderedAscending
                case .associatedCount:
                    let count1 = app1.associatedFileTypes.count
                    let count2 = app2.associatedFileTypes.count
                    return count1 > count2 || (count1 == count2 && app1.name < app2.name)
                case .recentUsed:
                    // 这里可以添加最近使用的逻辑
                    return false
                }
            }
        }
    }
    
    // 其他方法实现...
} 