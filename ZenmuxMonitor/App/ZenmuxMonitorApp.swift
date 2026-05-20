import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let viewModel = UsageViewModel()
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var appearanceObservation: NSKeyValueObservation?

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
        appearanceObservation = NSApp.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
            Task { @MainActor in self?.applyStatusBarStyle() }
        }
    }

    // Re-registers on every @Observable change to keep the title in sync.
    private func observeLabel() {
        withObservationTracking {
            _ = viewModel.subscriptionDetail?.quota5HourDisplay.usagePercentage
        } onChange: {
            Task { @MainActor in self.observeLabel() }
        }
        applyStatusBarStyle()
    }

    private func applyStatusBarStyle() {
        guard let button = statusItem.button else { return }
        if let pct = viewModel.subscriptionDetail?.quota5HourDisplay.usagePercentage {
            let color = quotaTintColor(pct: pct)
            let font = button.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
            button.attributedTitle = NSAttributedString(
                string: String(format: "%.0f%%", pct * 100),
                attributes: [.foregroundColor: color, .font: font]
            )
        } else {
            button.attributedTitle = NSAttributedString(string: "")
        }
    }

    private func quotaTintColor(pct: Double) -> NSColor {
        let display = SubscriptionDetail.QuotaWindowDisplay(
            label: "", is5Hour: true, usagePercentage: pct,
            flowsUsed: nil, flowsMax: 0, resetsAt: nil
        )
        if display.isHighUsage { return .systemRed }
        if display.isWarning { return .systemOrange }
        return .systemGreen
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: UsagePanel(viewModel: viewModel)
        )
        applyPopoverAppearance()
    }

    /// Setting an explicit appearance disables NSPopover vibrancy,
    /// which causes colored text to render with a halo in light mode.
    private func applyPopoverAppearance() {
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        popover.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
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
            applyPopoverAppearance()
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            if viewModel.hasAPIKey { viewModel.requestRefresh() }
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        let refresh = NSMenuItem(title: L("menu.refresh"), action: #selector(refreshAction), keyEquivalent: "")
        refresh.target = self
        let settings = NSMenuItem(title: L("menu.settings"), action: #selector(settingsAction), keyEquivalent: "")
        settings.target = self
        let quit = NSMenuItem(title: L("menu.quit"), action: #selector(quitAction), keyEquivalent: "")
        quit.target = self
        menu.addItem(refresh)
        menu.addItem(settings)
        menu.addItem(.separator())
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
}

@main
struct ZenmuxMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings { EmptyView() }
    }
}
