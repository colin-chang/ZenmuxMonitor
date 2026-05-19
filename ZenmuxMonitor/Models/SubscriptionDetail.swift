import Foundation

struct SubscriptionDetail: Codable, Sendable {
    let plan: PlanInfo
    let currency: String
    let baseUsdPerFlow: Double
    let effectiveUsdPerFlow: Double
    let accountStatus: String
    let quota5Hour: QuotaWindow
    let quota7Day: QuotaWindow
    let quotaMonthly: QuotaMonthly

    var quota5HourDisplay: QuotaWindowDisplay {
        QuotaWindowDisplay(
            label: "5 小时窗口",
            usagePercentage: quota5Hour.usagePercentage,
            flowsUsed: quota5Hour.usedFlows,
            flowsMax: quota5Hour.maxFlows,
            resetsAt: quota5Hour.resetsAt
        )
    }

    var quota7DayDisplay: QuotaWindowDisplay {
        QuotaWindowDisplay(
            label: "7 天窗口",
            usagePercentage: quota7Day.usagePercentage,
            flowsUsed: quota7Day.usedFlows,
            flowsMax: quota7Day.maxFlows,
            resetsAt: quota7Day.resetsAt
        )
    }

    struct PlanInfo: Codable, Sendable {
        let tier: String
        let amountUsd: Double
        let interval: String
        let expiresAt: String

        var displayName: String {
            tier.capitalized
        }

        enum CodingKeys: String, CodingKey {
            case tier, interval
            case amountUsd = "amount_usd"
            case expiresAt = "expires_at"
        }
    }

    struct QuotaWindow: Codable, Sendable {
        let usagePercentage: Double
        let resetsAt: String
        let maxFlows: Double
        let usedFlows: Double
        let remainingFlows: Double
        let usedValueUsd: Double
        let maxValueUsd: Double

        enum CodingKeys: String, CodingKey {
            case usagePercentage = "usage_percentage"
            case resetsAt = "resets_at"
            case maxFlows = "max_flows"
            case usedFlows = "used_flows"
            case remainingFlows = "remaining_flows"
            case usedValueUsd = "used_value_usd"
            case maxValueUsd = "max_value_usd"
        }
    }

    struct QuotaMonthly: Codable, Sendable {
        let maxFlows: Double
        let maxValueUsd: Double

        enum CodingKeys: String, CodingKey {
            case maxFlows = "max_flows"
            case maxValueUsd = "max_value_usd"
        }
    }

    struct QuotaWindowDisplay: Identifiable {
        let id = UUID()
        let label: String
        let usagePercentage: Double?
        let flowsUsed: Double?
        let flowsMax: Double
        let resetsAt: String?

        var isHighUsage: Bool { (usagePercentage ?? 0) > 0.8 }
        var isWarning: Bool { (usagePercentage ?? 0) > 0.5 }

        func resetCountdown() -> String? {
            guard let iso = resetsAt else { return nil }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard let target = formatter.date(from: iso) else { return nil }
            let interval = target.timeIntervalSinceNow
            guard interval > 0 else { return nil }

            let hours = Int(interval) / 3600
            let minutes = Int(interval) % 3600 / 60

            if label.contains("5") {
                if hours > 0 {
                    return "\(hours)小时\(minutes)分后重置"
                }
                return "\(minutes)分后重置"
            } else {
                let days = hours / 24
                let remainHours = hours % 24
                if days > 0 {
                    return "\(days)天\(remainHours)小时\(minutes)分后重置"
                }
                if remainHours > 0 {
                    return "\(remainHours)小时\(minutes)分后重置"
                }
                return "\(minutes)分后重置"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case plan, currency
        case baseUsdPerFlow = "base_usd_per_flow"
        case effectiveUsdPerFlow = "effective_usd_per_flow"
        case accountStatus = "account_status"
        case quota5Hour = "quota_5_hour"
        case quota7Day = "quota_7_day"
        case quotaMonthly = "quota_monthly"
    }
}

/// Top-level API response wrapper
struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T
}
