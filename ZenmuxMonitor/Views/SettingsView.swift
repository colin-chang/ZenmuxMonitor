import SwiftUI

struct SettingsView: View {
    let viewModel: UsageViewModel
    @State private var apiKeyInput = ""
    @State private var refreshInterval: TimeInterval = 300
    @State private var saveMessage = ""

    private let intervals: [(String, TimeInterval)] = [
        ("1 分钟", 60),
        ("5 分钟", 300),
        ("15 分钟", 900),
        ("30 分钟", 1800),
    ]

    var body: some View {
        Form {
            Section("Management API Key") {
                SecureField("sk-mgmt-...", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("保存") {
                        do {
                            try viewModel.saveAPIKey(apiKeyInput)
                            saveMessage = "已保存"
                            Task { await viewModel.refresh() }
                        } catch {
                            saveMessage = "保存失败：\(error.localizedDescription)"
                        }
                    }
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
                            .font(.caption)
                            .foregroundStyle(saveMessage.contains("失败") ? .red : .green)
                    }
                }

                HStack(spacing: 4) {
                    Text("获取 API Key →")
                        .font(.caption)
                    Link("zenmux.ai/platform/management",
                         destination: URL(string: "https://zenmux.ai/platform/management")!)
                        .font(.caption)
                }
            }

            Section("自动刷新") {
                Picker("间隔", selection: $refreshInterval) {
                    ForEach(intervals, id: \.1) { label, value in
                        Text(label).tag(value)
                    }
                }
                .onChange(of: refreshInterval) { _, newValue in
                    viewModel.startAutoRefresh(interval: newValue)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 260)
        .onAppear {
            if let key = KeychainManager.load(key: KeychainManager.accountKey) {
                apiKeyInput = key
            }
        }
    }
}
