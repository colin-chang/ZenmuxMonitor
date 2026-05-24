import Foundation

struct SubscriptionDetail: Codable, Sendable {
    let plan: PlanInfo?
    let currency: String?
    let baseUsdPerFlow: Double?
    let effectiveUsdPerFlow: Double?
    let accountStatus: String?
    let quota5Hour: QuotaWindow?
    let quota7Day: QuotaWindow?
    let quotaMonthly: QuotaMonthly?

    var quota5HourDisplay: QuotaWindowDisplay? {
        guard let q = quota5Hour else { return nil }
        return QuotaWindowDisplay(
            label: L("quota.5hour"),
            is5Hour: true,
            usagePercentage: q.usagePercentage,
            flowsUsed: q.usedFlows,
            flowsMax: q.maxFlows,
            resetsAt: q.resetsAt
        )
    }

    var quota7DayDisplay: QuotaWindowDisplay? {
        guard let q = quota7Day else { return nil }
        return QuotaWindowDisplay(
            label: L("quota.7day"),
            is5Hour: false,
            usagePercentage: q.usagePercentage,
            flowsUsed: q.usedFlows,
            flowsMax: q.maxFlows,
            resetsAt: q.resetsAt
        )
    }

    struct PlanInfo: Codable, Sendable {
        let tier: String
        let amountUsd: Double?
        let interval: String?
        let expiresAt: String?

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
        let usagePercentage: Double?
        let resetsAt: String?
        let maxFlows: Double?
        let usedFlows: Double?
        let remainingFlows: Double?
        let usedValueUsd: Double?
        let maxValueUsd: Double?

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
        let maxFlows: Double?
        let maxValueUsd: Double?

        enum CodingKeys: String, CodingKey {
            case maxFlows = "max_flows"
            case maxValueUsd = "max_value_usd"
        }
    }

    struct QuotaWindowDisplay: Identifiable {
        let id = UUID()
        let label: String
        let is5Hour: Bool
        let usagePercentage: Double?
        let flowsUsed: Double?
        let flowsMax: Double?
        let resetsAt: String?

        var isHighUsage: Bool { (usagePercentage ?? 0) > 0.8 }
        var isWarning: Bool { (usagePercentage ?? 0) > 0.5 }

        nonisolated(unsafe) private static let isoFormatter: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()

        nonisolated(unsafe) private static let absoluteFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd HH:mm"
            return f
        }()

        func resetAbsoluteTime() -> String? {
            guard let iso = resetsAt else { return nil }
            guard let target = Self.isoFormatter.date(from: iso) else { return nil }
            let timeString = Self.absoluteFormatter.string(from: target)
            return String(format: L("countdown.resets_at"), timeString)
        }

        func resetCountdown() -> String? {
            guard let iso = resetsAt else { return nil }
            let formatter = Self.isoFormatter
            guard let target = formatter.date(from: iso) else { return nil }
            let interval = target.timeIntervalSinceNow
            guard interval > 0 else { return nil }

            let hours = Int(interval) / 3600
            let minutes = Int(interval) % 3600 / 60

            if is5Hour {
                if hours > 0 {
                    return String(format: L("countdown.hours_minutes"), hours, minutes)
                }
                return String(format: L("countdown.minutes"), minutes)
            } else {
                let days = hours / 24
                let remainHours = hours % 24
                if days > 0 {
                    return String(format: L("countdown.days_hours_minutes"), days, remainHours, minutes)
                }
                if remainHours > 0 {
                    return String(format: L("countdown.hours_minutes"), remainHours, minutes)
                }
                return String(format: L("countdown.minutes"), minutes)
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
