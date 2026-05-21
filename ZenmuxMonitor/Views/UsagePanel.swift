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
            } else if let detail = viewModel.subscriptionDetail, let plan = detail.plan {
                HStack(spacing: 4) {
                    Text("ZenMux \(plan.displayName)")
                        .font(.title3.bold())
                    Image(systemName: tierIconName(for: plan.tier))
                        .foregroundStyle(tierIconColor(for: plan.tier))
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
        } else if let detail = viewModel.subscriptionDetail {
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) {
                    viewModel.requestRefresh()
                }
            }
            if let q = detail.quota5HourDisplay {
                QuotaRow(window: q)
                Divider().opacity(0.3)
            }
            if let q = detail.quota7DayDisplay {
                QuotaRow(window: q)
            }

            if let balance = viewModel.paygBalance {
                PAYGSection(balance: balance)
            }
            if let rate = viewModel.flowRate {
                FlowRateSection(rate: rate)
            }
        } else if let error = viewModel.errorMessage {
            ErrorBanner(message: error) {
                viewModel.requestRefresh()
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
                .font(.callout)
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
        VStack(spacing: 4) {
            HStack {
                if !viewModel.showSettings {
                    Button {
                        viewModel.preventSleep.toggle()
                    } label: {
                        Image(systemName: viewModel.preventSleep ? "eye.fill" : "eye.slash.fill")
                            .font(.footnote)
                    }
                    .buttonStyle(.plain)
                    .help(viewModel.preventSleep ? L("settings.prevent_sleep.on") : L("settings.prevent_sleep.off"))

                    Button {
                        viewModel.requestRefresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.footnote)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isLoading)
                    .help(L("menu.refresh"))
                }
                Spacer()
                if !viewModel.showSettings, let detail = viewModel.subscriptionDetail, let status = detail.accountStatus {
                    StatusBadge(status: status)
                }
            }

            if viewModel.showSettings {
                Text("To my love CJY, thanks for her support and companionship.")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Inline Settings

struct InlineSettingsView: View {
    @Bindable var viewModel: UsageViewModel
    @State private var apiKeyInput = ""
    @State private var saveMessage = ""
    @State private var updateChecker = UpdateChecker()
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L("settings.api_key"))
                    .font(.callout.bold())
                Spacer()
                HStack(spacing: 2) {
                    Link(L("settings.api_key.register"),
                         destination: URL(string: "https://zenmux.ai/invite/1C3QLF")!)
                        .font(.footnote)
                    Text(" -> ")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Link(L("settings.api_key.get"),
                         destination: URL(string: "https://zenmux.ai/platform/management")!)
                        .font(.footnote)
                }
            }

            // API Key field with inline action buttons
            HStack(spacing: 0) {
                SecureField(L("settings.api_key.placeholder"), text: $apiKeyInput)
                    .textFieldStyle(.plain)
                    .font(.callout)

                if viewModel.hasAPIKey {
                    Button {
                        viewModel.deleteAPIKey()
                        apiKeyInput = ""
                        saveMessage = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 20, height: 20)
                    .help(L("settings.delete"))
                }

                Button {
                    do {
                        try viewModel.saveAPIKey(apiKeyInput)
                        saveMessage = L("settings.saved")
                        viewModel.requestRefresh()
                    } catch {
                        saveMessage = L("settings.save_failed")
                    }
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .opacity(apiKeyInput.isEmpty ? 0.3 : 1)
                }
                .buttonStyle(.plain)
                .frame(width: 20, height: 20)
                .disabled(apiKeyInput.isEmpty)
                .padding(.leading, 4)
                .help(L("settings.save"))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.quaternary, lineWidth: 1)
            )

            if !saveMessage.isEmpty {
                Text(saveMessage)
                    .font(.footnote)
                    .foregroundStyle(saveMessage == L("settings.saved") ? .green : .red)
            }

            HStack {
                Text(L("settings.refresh_interval"))
                    .font(.callout)
                Spacer()
                Picker(L("settings.refresh_interval"), selection: $viewModel.refreshInterval) {
                    ForEach(intervals, id: \.1) { label, value in
                        Text(label).tag(value)
                    }
                }
                .labelsHidden()
                .font(.callout)
                .onChange(of: viewModel.refreshInterval) { _, newValue in
                    viewModel.startAutoRefresh(interval: newValue)
                }
            }

            HStack {
                Text(L("settings.language"))
                    .font(.callout)
                Spacer()
                Picker(L("settings.language"), selection: $langManager.currentLanguage) {
                    ForEach(LanguageManager.AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .labelsHidden()
                .font(.callout)
            }

            HStack {
                Text(L("settings.prevent_sleep"))
                    .font(.callout)
                Spacer()
                Toggle("", isOn: $viewModel.preventSleep)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
            }

            HStack {
                Text(L("settings.launch_at_login"))
                    .font(.callout)
                Spacer()
                Toggle("", isOn: $viewModel.launchAtLogin)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
            }

            versionSection
        }
        .onAppear {
            if let key = KeychainManager.load(key: KeychainManager.accountKey) {
                apiKeyInput = key
            }
        }
    }

    @ViewBuilder
    private var versionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("ZenMux Monitor ")
                    .font(.callout.bold())
                    .foregroundStyle(.secondary)
                + Text("v\(updateChecker.currentVersion)")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Spacer()

                if updateChecker.isUpdating {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.small)
                        Text(L("update.updating"))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        Task { await updateChecker.checkForUpdates() }
                    } label: {
                        if updateChecker.isChecking {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text(L("update.check"))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                    .font(.callout)
                    .disabled(updateChecker.isChecking)
                }
            }

            if let error = updateChecker.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            } else if let release = updateChecker.latestRelease, !updateChecker.isUpdating {
                if updateChecker.updateAvailable {
                    HStack {
                        Text(L("update.available"))
                            .font(.callout)
                            .foregroundStyle(.orange)
                        Spacer()
                        Button(L("update.now")) {
                            Task {
                                do {
                                    try await updateChecker.downloadAndInstall()
                                } catch {
                                    updateChecker.errorMessage = error.localizedDescription
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                } else {
                    Text(L("update.up_to_date"))
                        .font(.callout)
                        .foregroundStyle(.green)
                }
            }
        }

        Spacer().frame(height: 4)

        HStack {
            Spacer()
            Text("Authorized by")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Link("A-Nomad Studio", destination: URL(string: "mailto:business@a-nomad.com")!)
                .font(.footnote)
            Text("/")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Link("Colin", destination: URL(string: "https://github.com/colin-chang")!)
                .font(.footnote)
            Spacer()
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
                if let used = window.flowsUsed, let max = window.flowsMax {
                    Text("\(formatNumber(used)) / \(formatNumber(max)) \(L("quota.flows"))")
                } else if let max = window.flowsMax {
                    Text("\(formatNumber(max)) \(L("quota.flows"))")
                }
                Spacer()
                if let countdown = window.resetCountdown() {
                    MonospacedCountdownText(text: countdown)
                }
            }
            .font(.callout)
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
            .font(.system(.callout, design: .monospaced))
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
                LabeledContent(L("payg.total"), value: "$\(String(format: "%.2f", balance.totalCredits ?? 0))")
                LabeledContent(L("payg.top_up"), value: "$\(String(format: "%.2f", balance.topUpCredits ?? 0))")
                LabeledContent(L("payg.bonus"), value: "$\(String(format: "%.2f", balance.bonusCredits ?? 0))")
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
            if let perFlow = rate.effectiveUsdPerFlow {
                Text("$\(String(format: "%.5f", perFlow)) \(L("flow_rate.per_flow"))")
                    .font(.callout)
            }
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
            Button(action: onRetry) {
                Text(L("retry"))
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

#Preview("No API Key") {
    UsagePanel(viewModel: UsageViewModel())
}

#Preview("Settings") {
    let vm = UsageViewModel()
    vm.showSettings = true
    return UsagePanel(viewModel: vm)
}
