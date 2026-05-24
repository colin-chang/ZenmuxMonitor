import SwiftUI

struct InlineSettingsView: View {
    @Bindable var viewModel: UsageViewModel
    @State private var apiKeyInput = ""
    @State private var saveMessage = ""
    @State private var showSleepHelp = false
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
                Picker(L("settings.refresh_interval"), selection: Binding(get: { viewModel.refreshInterval }, set: { viewModel.refreshInterval = $0 })) {
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
                Picker(L("settings.language"), selection: Binding(get: { langManager.currentLanguage }, set: { langManager.currentLanguage = $0 })) {
                    ForEach(LanguageManager.AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .labelsHidden()
                .font(.callout)
            }

            HStack {
                HStack(spacing: 3) {
                    Text(L("settings.prevent_sleep"))
                        .font(.callout)
                    Button {
                        showSleepHelp.toggle()
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .background(SleepHelpPopover(isPresented: $showSleepHelp, text: L("settings.prevent_sleep.hint")))
                }
                Spacer()
                Toggle("", isOn: Binding(get: { viewModel.preventSleep }, set: { viewModel.preventSleep = $0 }))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
            }

            HStack {
                Text(L("settings.launch_at_login"))
                    .font(.callout)
                Spacer()
                Toggle("", isOn: Binding(get: { viewModel.launchAtLogin }, set: { viewModel.launchAtLogin = $0 }))
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
                        Text(String(format: L("update.available"), release.tagName))
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
