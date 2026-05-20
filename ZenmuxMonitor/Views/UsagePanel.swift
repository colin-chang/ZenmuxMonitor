import SwiftUI

struct UsagePanel: View {
    @Bindable var viewModel: UsageViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            if viewModel.showSettings {
                InlineSettingsView(viewModel: viewModel)
            } else if viewModel.hasAPIKey {
                content
            } else {
                noKeyView
            }
            Divider()
            footer
        }
        .padding()
        .frame(width: 340)
        .onAppear {
            if viewModel.hasAPIKey {
                viewModel.onPanelAppear()
            }
        }
        .onDisappear {
            viewModel.onPanelDisappear()
        }
        .onChange(of: viewModel.hasAPIKey) { _, hasKey in
            if hasKey && !viewModel.showSettings {
                viewModel.startAutoRefresh()
                viewModel.requestRefresh()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            if viewModel.showSettings {
                Button {
                    viewModel.showSettings = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Text(L("header.settings"))
                    .font(.title3.bold())
            } else if let detail = viewModel.subscriptionDetail {
                HStack(spacing: 4) {
                    Text("ZenMux \(detail.plan.displayName)")
                        .font(.title3.bold())
                    Image(systemName: tierIconName(for: detail.plan.tier))
                        .foregroundStyle(tierIconColor(for: detail.plan.tier))
                        .font(.callout)
                }
            } else {
                Text("ZenMux")
                    .font(.title3.bold())
            }
            Spacer()
            if !viewModel.showSettings {
                Button {
                    viewModel.showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.body)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func tierIconName(for tier: String) -> String {
        switch tier.lowercased() {
        case "ultra": "crown.fill"
        case "pro": "star.fill"
        default: "circle.fill"
        }
    }

    private func tierIconColor(for tier: String) -> Color {
        switch tier.lowercased() {
        case "ultra": .yellow
        case "pro": .purple
        default: .secondary
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.subscriptionDetail == nil {
            ProgressView(L("loading"))
                .frame(maxWidth: .infinity)
        } else if let error = viewModel.errorMessage {
            ErrorBanner(message: error) {
                viewModel.requestRefresh()
            }
        } else if let detail = viewModel.subscriptionDetail {
            QuotaRow(window: detail.quota5HourDisplay)
            Divider().opacity(0.3)
            QuotaRow(window: detail.quota7DayDisplay)

            if let balance = viewModel.paygBalance {
                PAYGSection(balance: balance)
            }
            if let rate = viewModel.flowRate {
                FlowRateSection(rate: rate)
            }
        }
    }

    // MARK: - No Key

    private var noKeyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "key.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(L("no_api_key"))
                .font(.body)
            Button(L("configure_api_key")) {
                viewModel.showSettings = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if !viewModel.showSettings {
                Button {
                    viewModel.requestRefresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.footnote)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
            }
            Spacer()
            if !viewModel.showSettings, let detail = viewModel.subscriptionDetail {
                StatusBadge(status: detail.accountStatus)
            }
        }
    }
}

// MARK: - Inline Settings

struct InlineSettingsView: View {
    @Bindable var viewModel: UsageViewModel
    @State private var apiKeyInput = ""
    @State private var saveMessage = ""
    @Bindable private var langManager = LanguageManager.shared

    private var intervals: [(String, TimeInterval)] {
        [
            (L("settings.interval.1min"), 60),
            (L("settings.interval.5min"), 300),
            (L("settings.interval.15min"), 900),
            (L("settings.interval.30min"), 1800),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L("settings.api_key"))
                    .font(.callout.bold())
                Spacer()
                Link(L("settings.api_key.get"),
                     destination: URL(string: "https://zenmux.ai/platform/management")!)
                    .font(.footnote)
            }

            SecureField(L("settings.api_key.placeholder"), text: $apiKeyInput)
                .textFieldStyle(.roundedBorder)
                .font(.callout)

            HStack(spacing: 8) {
                Button(L("settings.save")) {
                    do {
                        try viewModel.saveAPIKey(apiKeyInput)
                        saveMessage = L("settings.saved")
                        viewModel.requestRefresh()
                    } catch {
                        saveMessage = L("settings.save_failed")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(apiKeyInput.isEmpty)

                if viewModel.hasAPIKey {
                    Button(L("settings.delete"), role: .destructive) {
                        viewModel.deleteAPIKey()
                        apiKeyInput = ""
                        saveMessage = ""
                    }
                }

                if !saveMessage.isEmpty {
                    Text(saveMessage)
                        .font(.footnote)
                        .foregroundStyle(saveMessage == L("settings.saved") ? .green : .red)
                }
            }

            Divider()

            Picker(L("settings.refresh_interval"), selection: $viewModel.refreshInterval) {
                ForEach(intervals, id: \.1) { label, value in
                    Text(label).tag(value)
                }
            }
            .font(.callout)
            .onChange(of: viewModel.refreshInterval) { _, newValue in
                viewModel.startAutoRefresh(interval: newValue)
            }

            Divider()

            Picker(L("settings.language"), selection: $langManager.currentLanguage) {
                ForEach(LanguageManager.AppLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .font(.callout)
        }
        .onAppear {
            if let key = KeychainManager.load(key: KeychainManager.accountKey) {
                apiKeyInput = key
            }
        }
    }
}

// MARK: - Sub-views

struct StatusBadge: View {
    let status: String

    var color: Color {
        status == "healthy" ? .green : .orange
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(status)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

struct ProgressBar: View {
    let value: Double
    let color: Color

    private var clamped: Double { max(0, min(1, value)) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule().fill(color)
                    .frame(width: geo.size.width * CGFloat(clamped))
            }
        }
        .frame(height: 4)
    }
}

struct QuotaRow: View {
    let window: SubscriptionDetail.QuotaWindowDisplay

    private var progressColor: Color {
        window.isHighUsage ? .red : window.isWarning ? .orange : .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(window.label)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                if let pct = window.usagePercentage {
                    Text(String(format: "%.2f%%", pct * 100))
                        .font(.callout.bold())
                        .foregroundStyle(progressColor)
                } else {
                    Text("—")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            if let pct = window.usagePercentage {
                ProgressBar(value: pct, color: progressColor)
            }

            HStack {
                if let used = window.flowsUsed {
                    Text("\(formatNumber(used)) / \(formatNumber(window.flowsMax)) \(L("quota.flows"))")
                } else {
                    Text("\(formatNumber(window.flowsMax)) \(L("quota.flows"))")
                }
                Spacer()
                if let countdown = window.resetCountdown() {
                    MonospacedCountdownText(text: countdown)
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private func formatNumber(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "%.1fK", value / 1_000) }
        return String(format: "%.1f", value)
    }
}

struct MonospacedCountdownText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.footnote, design: .monospaced))
    }
}

struct PAYGSection: View {
    let balance: PAYGBalance

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L("payg.balance"))
                .font(.callout)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                LabeledContent(L("payg.total"), value: "$\(String(format: "%.2f", balance.totalCredits))")
                LabeledContent(L("payg.top_up"), value: "$\(String(format: "%.2f", balance.topUpCredits))")
                LabeledContent(L("payg.bonus"), value: "$\(String(format: "%.2f", balance.bonusCredits))")
            }
            .font(.callout)
        }
    }
}

struct FlowRateSection: View {
    let rate: FlowRate

    var body: some View {
        HStack {
            Text(L("flow_rate"))
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Text("$\(String(format: "%.5f", rate.effectiveUsdPerFlow)) \(L("flow_rate.per_flow"))")
                .font(.callout)
        }
    }
}

struct ErrorBanner: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(L("retry"), action: onRetry)
                .buttonStyle(.bordered)
                .controlSize(.regular)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}
