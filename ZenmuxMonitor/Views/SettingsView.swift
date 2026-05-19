import SwiftUI

struct SettingsView: View {
    let viewModel: UsageViewModel
    @State private var apiKeyInput = ""
    @State private var refreshInterval: TimeInterval = 300
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
        Form {
            Section(L("settings.api_key")) {
                SecureField(L("settings.api_key.placeholder"), text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button(L("settings.save")) {
                        do {
                            try viewModel.saveAPIKey(apiKeyInput)
                            saveMessage = L("settings.saved")
                            Task { await viewModel.refresh() }
                        } catch {
                            saveMessage = L("settings.save_failed")
                        }
                    }
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
                            .font(.caption)
                            .foregroundStyle(saveMessage == L("settings.saved") ? .green : .red)
                    }
                }

                HStack(spacing: 4) {
                    Text("\(L("settings.api_key.get")) API Key →")
                        .font(.caption)
                    Link("zenmux.ai/platform/management",
                         destination: URL(string: "https://zenmux.ai/platform/management")!)
                        .font(.caption)
                }
            }

            Section(L("settings.refresh_interval")) {
                Picker(L("settings.refresh_interval"), selection: $refreshInterval) {
                    ForEach(intervals, id: \.1) { label, value in
                        Text(label).tag(value)
                    }
                }
                .onChange(of: refreshInterval) { _, newValue in
                    viewModel.startAutoRefresh(interval: newValue)
                }
            }

            Section(L("settings.language")) {
                Picker(L("settings.language"), selection: $langManager.currentLanguage) {
                    ForEach(LanguageManager.AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 320)
        .onAppear {
            if let key = KeychainManager.load(key: KeychainManager.accountKey) {
                apiKeyInput = key
            }
        }
    }
}
