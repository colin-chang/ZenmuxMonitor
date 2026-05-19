import SwiftUI

struct UsagePanel: View {
    @Bindable var viewModel: UsageViewModel
    @State private var showingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            if showingSettings {
                InlineSettingsView(viewModel: viewModel, isPresented: $showingSettings)
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
        .contextMenu {
            Button("刷新") { viewModel.requestRefresh() }
            Button("设置…") { showingSettings = true }
            Divider()
            Button("退出") { NSApp.terminate(nil) }
        }
        .onAppear {
            if viewModel.hasAPIKey {
                viewModel.onPanelAppear()
            }
        }
        .onDisappear {
            viewModel.onPanelDisappear()
        }
        .onChange(of: viewModel.hasAPIKey) { _, hasKey in
            if hasKey && !showingSettings {
                viewModel.startAutoRefresh()
                viewModel.requestRefresh()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            if showingSettings {
                Button {
                    showingSettings = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Text("设置")
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
            if !showingSettings {
                Button {
                    showingSettings = true
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
            ProgressView("加载中…")
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
            Text("未配置 API Key")
                .font(.body)
            Button("配置 API Key") {
                showingSettings = true
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
            if !showingSettings {
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
            if !showingSettings, let detail = viewModel.subscriptionDetail {
                StatusBadge(status: detail.accountStatus)
            }
        }
    }
}

// MARK: - Inline Settings

struct InlineSettingsView: View {
    @Bindable var viewModel: UsageViewModel
    @Binding var isPresented: Bool
    @State private var apiKeyInput = ""
    @State private var saveMessage = ""

    private let intervals: [(String, TimeInterval)] = [
        ("1 分钟", 60),
        ("5 分钟", 300),
        ("15 分钟", 900),
        ("30 分钟", 1800),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("API Key")
                    .font(.callout.bold())
                Spacer()
                Link("获取",
                     destination: URL(string: "https://zenmux.ai/platform/management")!)
                    .font(.footnote)
            }

            SecureField("Management API Key", text: $apiKeyInput)
                .textFieldStyle(.roundedBorder)
                .font(.callout)

            HStack(spacing: 8) {
                Button("保存") {
                    do {
                        try viewModel.saveAPIKey(apiKeyInput)
                        saveMessage = "已保存"
                        viewModel.requestRefresh()
                    } catch {
                        saveMessage = "失败"
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(apiKeyInput.isEmpty)

                if viewModel.hasAPIKey {
                    Button("删除", role: .destructive) {
                        viewModel.deleteAPIKey()
                        apiKeyInput = ""
                        saveMessage = ""
                    }
                }

                if !saveMessage.isEmpty {
                    Text(saveMessage)
                        .font(.footnote)
                        .foregroundStyle(saveMessage == "已保存" ? .green : .red)
                }
            }

            Divider()

            Picker("刷新间隔", selection: $viewModel.refreshInterval) {
                ForEach(intervals, id: \.1) { label, value in
                    Text(label).tag(value)
                }
            }
            .font(.callout)
            .onChange(of: viewModel.refreshInterval) { _, newValue in
                viewModel.startAutoRefresh(interval: newValue)
            }
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
                ProgressView(value: pct)
                    .progressViewStyle(.linear)
                    .tint(progressColor)
            }

            HStack {
                if let used = window.flowsUsed {
                    Text("\(formatNumber(used)) / \(formatNumber(window.flowsMax)) Flows")
                } else {
                    Text("\(formatNumber(window.flowsMax)) Flows")
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
            Text("PAYG 余额")
                .font(.callout)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                LabeledContent("总计", value: "$\(String(format: "%.2f", balance.totalCredits))")
                LabeledContent("充值", value: "$\(String(format: "%.2f", balance.topUpCredits))")
                LabeledContent("赠送", value: "$\(String(format: "%.2f", balance.bonusCredits))")
            }
            .font(.callout)
        }
    }
}

struct FlowRateSection: View {
    let rate: FlowRate

    var body: some View {
        HStack {
            Text("Flow 汇率")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Text("$\(String(format: "%.5f", rate.effectiveUsdPerFlow)) / Flow")
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
            Button("重试", action: onRetry)
                .buttonStyle(.bordered)
                .controlSize(.regular)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}
