import SwiftUI

struct QuotaRow: View {
    let window: SubscriptionDetail.QuotaWindowDisplay
    @State private var showAbsoluteTime = false

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
                if let countdown = window.resetCountdown(),
                   let absolute = window.resetAbsoluteTime() {
                    Button {
                        showAbsoluteTime.toggle()
                    } label: {
                        Text(showAbsoluteTime ? absolute : countdown)
                            .font(.system(.callout, design: .monospaced))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .help(L("countdown.click_to_toggle"))
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

#Preview {
    let detail = SubscriptionDetail(
        plan: nil,
        currency: nil,
        baseUsdPerFlow: nil,
        effectiveUsdPerFlow: nil,
        accountStatus: nil,
        quota5Hour: nil,
        quota7Day: nil,
        quotaMonthly: nil
    )
    let display = SubscriptionDetail.QuotaWindowDisplay(
        label: "5 Hours",
        is5Hour: true,
        usagePercentage: 0.65,
        flowsUsed: 1234,
        flowsMax: 2000,
        resetsAt: nil
    )
    return QuotaRow(window: display)
        .padding()
}
