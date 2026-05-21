import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
final class UsageViewModel: @unchecked Sendable {
    var subscriptionDetail: SubscriptionDetail?
    var paygBalance: PAYGBalance?
    var flowRate: FlowRate?
    var isLoading = false
    var lastUpdated: Date?
    var errorMessage: String?
    var showSettings = false

    private let client = ZenmuxAPIClient()
    private var refreshTimer: Timer?
    private var autoRefreshStarted = false
    private var sleepAssertionID: (any NSObjectProtocol)?

    private static let refreshIntervalKey = "refreshInterval"
    private static let preventSleepKey = "preventSleep"

    var refreshInterval: TimeInterval {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: Self.refreshIntervalKey) }
    }

    var hasAPIKey: Bool {
        guard let key = KeychainManager.load(key: KeychainManager.accountKey) else { return false }
        return !key.isEmpty
    }

    var preventSleep = UserDefaults.standard.bool(forKey: "preventSleep") {
        didSet {
            UserDefaults.standard.set(preventSleep, forKey: Self.preventSleepKey)
            if preventSleep { startSleepPrevention() } else { stopSleepPrevention() }
        }
    }

    var launchAtLogin = SMAppService.mainApp.status == .enabled {
        didSet {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                launchAtLogin = oldValue
                errorMessage = error.localizedDescription
            }
        }
    }

    init() {
        self.refreshInterval = UserDefaults.standard.double(forKey: Self.refreshIntervalKey)
        if self.refreshInterval == 0 { self.refreshInterval = 300 }
        if preventSleep {
            startSleepPrevention()
        }
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        async let detailTask = client.fetchSubscriptionDetail()
        async let balanceTask = client.fetchPAYGBalance()
        async let rateTask = client.fetchFlowRate()

        var errors: [String] = []

        do { subscriptionDetail = try await detailTask } catch { errors.append(error.localizedDescription) }
        do { paygBalance = try await balanceTask } catch { errors.append(error.localizedDescription) }
        do { flowRate = try await rateTask } catch { errors.append(error.localizedDescription) }

        if !errors.isEmpty {
            errorMessage = errors.joined(separator: "\n")
        }

        if subscriptionDetail != nil || paygBalance != nil || flowRate != nil {
            lastUpdated = Date()
        }

        isLoading = false
    }

    func requestRefresh() {
        Task {
            await refresh()
        }
    }

    func startSleepPrevention() {
        guard sleepAssertionID == nil else { return }
        sleepAssertionID = ProcessInfo.processInfo.beginActivity(
            options: [.idleSystemSleepDisabled, .userInitiated],
            reason: "Preventing sleep for remote access"
        )
    }

    func stopSleepPrevention() {
        guard let id = sleepAssertionID else { return }
        ProcessInfo.processInfo.endActivity(id)
        sleepAssertionID = nil
    }

    func onPanelAppear() {
        requestRefresh()
        if !autoRefreshStarted {
            startAutoRefresh()
            autoRefreshStarted = true
        }
    }

    func onPanelDisappear() {
        // no-op, keep auto-refresh running in background
    }

    func startAutoRefresh(interval: TimeInterval? = nil) {
        if let interval { refreshInterval = interval }
        stopAutoRefresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.refresh()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        autoRefreshStarted = false
    }

    func saveAPIKey(_ key: String) throws {
        try KeychainManager.save(key: KeychainManager.accountKey, value: key)
    }

    func deleteAPIKey() {
        KeychainManager.delete(key: KeychainManager.accountKey)
        subscriptionDetail = nil
        paygBalance = nil
        flowRate = nil
        lastUpdated = nil
        errorMessage = nil
    }
}
