import Foundation

struct FlowRate: Codable, Sendable {
    let currency: String?
    let baseUsdPerFlow: Double?
    let effectiveUsdPerFlow: Double?

    enum CodingKeys: String, CodingKey {
        case currency
        case baseUsdPerFlow = "base_usd_per_flow"
        case effectiveUsdPerFlow = "effective_usd_per_flow"
    }
}
