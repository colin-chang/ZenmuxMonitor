import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let viewModel = UsageViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct ZenmuxMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            UsagePanel(viewModel: appDelegate.viewModel)
        } label: {
            if let pct = appDelegate.viewModel.subscriptionDetail?.quota5HourDisplay.usagePercentage {
                Text(String(format: "%.0f%%", pct * 100))
            }
            Image("menu-icon")
        }
        .menuBarExtraStyle(.window)
    }
}
