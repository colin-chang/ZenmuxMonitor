import Foundation
import IOKit.pwr_mgt
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
    private var sleepAssertionID: IOPMAssertionID = 0

    private static let refreshIntervalKey = "refreshInterval"
    private static let preventSleepKey = "preventSleep"

    private var _refreshInterval: TimeInterval = 300

    var refreshInterval: TimeInterval {
        get { _refreshInterval }
        set {
            _refreshInterval = newValue
            UserDefaults.standard.set(newValue, forKey: Self.refreshIntervalKey)
        }
    }

    var hasAPIKey: Bool {
        guard let key = KeychainManager.load(key: KeychainManager.accountKey) else { return false }
        return !key.isEmpty
    }

    private var _preventSleep = UserDefaults.standard.bool(forKey: "preventSleep")
    private var _launchAtLogin = SMAppService.mainApp.status == .enabled

    var preventSleep: Bool {
        get { _preventSleep }
        set {
            _preventSleep = newValue
            UserDefaults.standard.set(newValue, forKey: Self.preventSleepKey)
            if newValue { startSleepPrevention() } else { stopSleepPrevention() }
        }
    }

    var launchAtLogin: Bool {
        get { _launchAtLogin }
        set {
            _launchAtLogin = newValue
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                _launchAtLogin = !newValue
                errorMessage = error.localizedDescription
            }
        }
    }

    init() {
        let stored = UserDefaults.standard.double(forKey: Self.refreshIntervalKey)
        _refreshInterval = stored > 0 ? stored : 300
        if preventSleep {
            startSleepPrevention()
        }
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        var errors: [String] = []

        do {
            subscriptionDetail = try await client.fetchSubscriptionDetail()
        } catch {
            errors.append(error.localizedDescription)
        }

        do {
            paygBalance = try await client.fetchPAYGBalance()
        } catch {
            errors.append(error.localizedDescription)
        }

        do {
            flowRate = try await client.fetchFlowRate()
        } catch {
            errors.append(error.localizedDescription)
        }

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
        guard sleepAssertionID == 0 else { return }
        let reason = "Preventing sleep for remote access" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &sleepAssertionID
        )
        if result != kIOReturnSuccess {
            sleepAssertionID = 0
        }
    }

    func stopSleepPrevention() {
        guard sleepAssertionID != 0 else { return }
        IOPMAssertionRelease(sleepAssertionID)
        sleepAssertionID = 0
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
