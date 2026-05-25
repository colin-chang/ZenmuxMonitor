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

#Preview("No API Key") {
    UsagePanel(viewModel: UsageViewModel())
}

#Preview("Settings") {
    let vm = UsageViewModel()
    vm.showSettings = true
    return UsagePanel(viewModel: vm)
}
