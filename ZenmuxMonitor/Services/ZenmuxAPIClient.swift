import Foundation

actor ZenmuxAPIClient {
    private let baseURL = URL(string: "https://zenmux.ai")!
    private let session: URLSession
    private let timeout: TimeInterval = 10

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
    }

    func fetchSubscriptionDetail() async throws -> SubscriptionDetail {
        try await request(path: "/api/v1/management/subscription/detail")
    }

    func fetchPAYGBalance() async throws -> PAYGBalance {
        try await request(path: "/api/v1/management/payg/balance")
    }

    func fetchFlowRate() async throws -> FlowRate {
        try await request(path: "/api/v1/management/flow_rate")
    }

    private func request<T: Decodable>(path: String) async throws -> T {
        guard let key = KeychainManager.load(key: KeychainManager.accountKey), !key.isEmpty else {
            throw APIError.missingKey
        }

        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401, 403:
            throw APIError.unauthorized
        case 422:
            throw APIError.rateLimited
        default:
            throw APIError.httpError(httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            // API wraps responses in { "success": true, "data": ... }
            let wrapper = try decoder.decode(APIResponse<T>.self, from: data)
            guard wrapper.success else {
                throw APIError.apiError
            }
            guard let responseData = wrapper.data else {
                throw APIError.decodingError(DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: [], debugDescription: "Response data is null")))
            }
            return responseData
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingError(error)
        }
    }

    enum APIError: LocalizedError {
        case missingKey
        case unauthorized
        case rateLimited
        case networkError(Error)
        case invalidResponse
        case httpError(Int)
        case decodingError(Error)
        case apiError

        var errorDescription: String? {
            switch self {
            case .missingKey:
                L("error.missing_key")
            case .unauthorized:
                L("error.unauthorized")
            case .rateLimited:
                L("error.rate_limited")
            case .networkError(let error):
                String(format: L("error.network"), error.localizedDescription)
            case .invalidResponse:
                L("error.invalid_response")
            case .httpError(let code):
                String(format: L("error.http"), code)
            case .decodingError(let error):
                String(format: L("error.decoding"), error.localizedDescription)
            case .apiError:
                L("error.api")
            }
        }
    }
}
