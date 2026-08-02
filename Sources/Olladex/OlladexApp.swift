import SwiftUI

@main
struct OlladexApp: App {
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .frame(minWidth: 760, minHeight: 560)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 640)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Refresh status") { Task { await store.refresh() } }
                    .keyboardShortcut("r")
            }
        }
    }
}
