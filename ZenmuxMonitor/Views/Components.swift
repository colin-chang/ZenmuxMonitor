import SwiftUI

// MARK: - Shared sub-views used by UsagePanel

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
