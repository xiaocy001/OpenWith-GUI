import SwiftUI

@main
struct OpenWithGUIApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .defaultSize(width: 1200, height: 760)
    }
}
