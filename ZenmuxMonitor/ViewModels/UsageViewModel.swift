import Foundation
import Observation

@MainActor
@Observable
final class UsageViewModel: @unchecked Sendable {
    var subscriptionDetail: SubscriptionDetail?
    var paygBalance: PAYGBalance?
    var flowRate: FlowRate?
    var isLoading = false
    var lastUpdated: Date?
    var errorMessage: String?

    private let client = ZenmuxAPIClient()
    private var refreshTimer: Timer?
    private var autoRefreshStarted = false

    private static let refreshIntervalKey = "refreshInterval"

    var refreshInterval: TimeInterval {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: Self.refreshIntervalKey) }
    }

    var hasAPIKey: Bool {
        guard let key = KeychainManager.load(key: KeychainManager.accountKey) else { return false }
        return !key.isEmpty
    }

    init() {
        self.refreshInterval = UserDefaults.standard.double(forKey: Self.refreshIntervalKey)
        if self.refreshInterval == 0 { self.refreshInterval = 300 }
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            async let sub = client.fetchSubscriptionDetail()
            async let payg = client.fetchPAYGBalance()
            async let flow = client.fetchFlowRate()

            let (subscription, balance, rate) = try await (sub, payg, flow)

            self.subscriptionDetail = subscription
            self.paygBalance = balance
            self.flowRate = rate
            self.lastUpdated = Date()
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func requestRefresh() {
        isLoading = false
        Task {
            await refresh()
        }
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
