import SwiftUI

@main
struct CXResApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar only — settings window managed by AppDelegate
        Settings { EmptyView() }
    }
}
