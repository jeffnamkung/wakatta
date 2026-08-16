import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case rateLimited
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .httpError(let code): return "HTTP error \(code)"
        case .rateLimited: return "Rate limited. Please wait and try again."
        case .decodingError(let error): return "Failed to parse response: \(error.localizedDescription)"
        }
    }
}

actor APIClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetch<T: Decodable>(_ url: URL, headers: [String: String] = [:]) async throws -> T {
        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return try await fetch(request)
    }

    func fetch<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.httpError(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func post<T: Decodable>(
        _ url: URL,
        body: Data?,
        headers: [String: String] = [:]
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return try await fetch(request)
    }
}
