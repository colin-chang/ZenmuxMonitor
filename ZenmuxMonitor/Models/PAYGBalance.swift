import Foundation

struct PAYGBalance: Codable, Sendable {
    let currency: String?
    let totalCredits: Double?
    let topUpCredits: Double?
    let bonusCredits: Double?

    enum CodingKeys: String, CodingKey {
        case currency
        case totalCredits = "total_credits"
        case topUpCredits = "top_up_credits"
        case bonusCredits = "bonus_credits"
    }
}
