import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationSplitView {
            AppListView(viewModel: viewModel)
        } detail: {
            FileTypeListView(viewModel: viewModel)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
