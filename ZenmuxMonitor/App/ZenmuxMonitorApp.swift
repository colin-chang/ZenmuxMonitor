import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let viewModel = UsageViewModel()
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPopover()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.image = NSImage(named: "menu-icon")
        button.imagePosition = .imageLeft
        button.action = #selector(handleClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.target = self
        observeLabel()
    }

    // Re-registers on every @Observable change to keep the title in sync.
    private func observeLabel() {
        withObservationTracking {
            if let pct = viewModel.subscriptionDetail?.quota5HourDisplay?.usagePercentage {
                statusItem.button?.title = String(format: "%.0f%%", pct * 100)
            } else {
                statusItem.button?.title = ""
            }
        } onChange: {
            Task { @MainActor in self.observeLabel() }
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: UsagePanel(viewModel: viewModel)
        )
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            fixVibrancy()
            if viewModel.hasAPIKey { viewModel.requestRefresh() }
        }
    }

    /// Walk popover view hierarchy to configure internal NSVisualEffectView
    /// blending mode, preventing halo on colored text in light mode while
    /// keeping the window semi-transparent.
    private func fixVibrancy() {
        guard let contentView = popover.contentViewController?.view else { return }
        var parent: NSView? = contentView.superview
        while parent != nil {
            if let vef = parent as? NSVisualEffectView {
                vef.material = .popover
                vef.state = .active
                vef.blendingMode = .withinWindow
            }
            parent = parent?.superview
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        let refresh = NSMenuItem(title: L("menu.refresh"), action: #selector(refreshAction), keyEquivalent: "")
        refresh.target = self
        let settings = NSMenuItem(title: L("menu.settings"), action: #selector(settingsAction), keyEquivalent: "")
        settings.target = self

        let preventSleep = NSMenuItem(title: L("menu.prevent_sleep"), action: #selector(togglePreventSleep), keyEquivalent: "")
        preventSleep.target = self
        preventSleep.state = viewModel.preventSleep ? .on : .off

        let launchAtLogin = NSMenuItem(title: L("menu.launch_at_login"), action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLogin.target = self
        launchAtLogin.state = viewModel.launchAtLogin ? .on : .off

        menu.addItem(refresh)
        menu.addItem(preventSleep)
        menu.addItem(launchAtLogin)
        menu.addItem(.separator())
        menu.addItem(settings)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: L("menu.quit"), action: #selector(quitAction), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        // Temporarily assign so NSStatusItem positions the menu correctly below the icon.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func refreshAction() { viewModel.requestRefresh() }
    @objc private func settingsAction() {
        viewModel.showSettings = true
        guard let button = statusItem.button, !popover.isShown else { return }
        togglePopover(button)
    }
    @objc private func quitAction() { NSApp.terminate(nil) }
    @objc private func togglePreventSleep() { viewModel.preventSleep.toggle() }
    @objc private func toggleLaunchAtLogin() { viewModel.launchAtLogin.toggle() }
}

@main
struct ZenmuxMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings { EmptyView() }
    }
}
