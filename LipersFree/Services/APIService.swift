//
//  APIService.swift
//  LipersFree
//

import Foundation

enum APIServiceError: LocalizedError {
    case invalidURL
    case badStatusCode(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The endpoint URL is invalid."
        case .badStatusCode(let code):
            "The server returned an unexpected status code: \(code)."
        }
    }
}

struct CategoriesResponse: Codable {
    let data: [Category]
}

struct SingleWallpaperResponse: Codable {
    let data: Wallpaper
}

final class APIService {
    static let shared = APIService()

    private let session: URLSession
    private let baseURLString = "https://liper.codecrew360.xyz/api/v1"

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCategories() async throws -> [Category] {
        guard let url = URL(string: "\(baseURLString)/categories") else {
            throw APIServiceError.invalidURL
        }
        let response: CategoriesResponse = try await performRequest(for: url)
        return response.data
    }

    func fetchHome() async throws -> HomeResponse {
        guard let url = URL(string: "\(baseURLString)/home") else {
            throw APIServiceError.invalidURL
        }
        return try await performRequest(for: url)
    }

    func fetchWallpapers(categoryId: Int? = nil, page: Int = 1) async throws -> WallpaperResponse {
        var components = URLComponents(string: "\(baseURLString)/wallpapers")
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "page", value: String(page))]
        if let categoryId {
            queryItems.append(URLQueryItem(name: "category_id", value: String(categoryId)))
        }
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw APIServiceError.invalidURL
        }
        return try await performRequest(for: url)
    }

    func fetchWallpaper(id: Int) async throws -> Wallpaper {
        guard let url = URL(string: "\(baseURLString)/wallpapers/\(id)") else {
            throw APIServiceError.invalidURL
        }
        let response: SingleWallpaperResponse = try await performRequest(for: url)
        return response.data
    }

    private func performRequest<T: Decodable>(for url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.badStatusCode(-1)
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw APIServiceError.badStatusCode(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}
