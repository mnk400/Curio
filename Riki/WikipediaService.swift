//
//  WikipediaService.swift
//  Riki
//
//  Created by Manik on 5/1/25.
//

import Foundation

// MARK: - Wikipedia Service Protocol

/// Protocol defining the interface for Wikipedia article fetching
protocol WikipediaServiceProtocol {
    /// Fetches a random Wikipedia article
    /// - Returns: A WikiArticle containing the article data
    /// - Throws: WikipediaError if the request fails
    func fetchRandomArticle() async throws -> WikiArticle
}

// MARK: - Wikipedia Errors

/// Errors that can occur when fetching Wikipedia articles
enum WikipediaError: LocalizedError {
    case invalidURL
    case noData
    case parsingError(String)
    case networkError(Error)
    case articleNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Wikipedia URL"
        case .noData:
            return "No data received from Wikipedia"
        case .parsingError(let message):
            return "Failed to parse article: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .articleNotFound:
            return "Article not found"
        }
    }
}

// MARK: - Wikipedia Service

/// Service responsible for fetching Wikipedia articles from the Wikipedia API
final class WikipediaService: WikipediaServiceProtocol {
    
    static let shared = WikipediaService()
    
    private let urlSession: URLSession
    private let jsonDecoder: JSONDecoder
    
    private enum APIConstants {
        static let randomSummaryURL = "https://en.wikipedia.org/api/rest_v1/page/random/summary"
        static let requestTimeout: TimeInterval = 30
        static let resourceTimeout: TimeInterval = 60
    }
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConstants.requestTimeout
        configuration.timeoutIntervalForResource = APIConstants.resourceTimeout
        configuration.waitsForConnectivity = true
        
        self.urlSession = URLSession(configuration: configuration)
        self.jsonDecoder = JSONDecoder()
    }
    
    /// Fetches a random Wikipedia article summary
    /// - Returns: A WikiArticle containing the article data
    /// - Throws: WikipediaError if the request fails
    func fetchRandomArticle() async throws -> WikiArticle {
        let summaryResponse = try await fetchRandomArticleSummary()
        return createArticleFromSummary(summaryResponse)
    }
    
    /// Fetches a random article summary from the Wikipedia API
    /// - Returns: WikipediaDetailResponse containing the raw API response
    /// - Throws: WikipediaError if the request fails
    private func fetchRandomArticleSummary() async throws -> WikipediaDetailResponse {
        guard let url = URL(string: APIConstants.randomSummaryURL) else {
            throw WikipediaError.invalidURL
        }
        
        do {
            let (data, response) = try await urlSession.data(from: url)
            
            try validateHTTPResponse(response)
            try validateResponseData(data)
            
            return try jsonDecoder.decode(WikipediaDetailResponse.self, from: data)
            
        } catch let decodingError as DecodingError {
            throw WikipediaError.parsingError("Failed to decode summary: \(decodingError.localizedDescription)")
        } catch let wikipediaError as WikipediaError {
            throw wikipediaError
        } catch {
            throw WikipediaError.networkError(error)
        }
    }
    
    /// Validates the HTTP response from the Wikipedia API
    /// - Parameter response: The URLResponse to validate
    /// - Throws: WikipediaError.networkError if the response is invalid
    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WikipediaError.networkError(URLError(.badServerResponse))
        }
        
        guard httpResponse.statusCode == 200 else {
            throw WikipediaError.networkError(URLError(.badServerResponse))
        }
    }
    
    /// Validates that the response data is not empty
    /// - Parameter data: The response data to validate
    /// - Throws: WikipediaError.noData if the data is empty
    private func validateResponseData(_ data: Data) throws {
        guard !data.isEmpty else {
            throw WikipediaError.noData
        }
    }
    
    /// Creates a WikiArticle from the API response
    /// - Parameter response: The WikipediaDetailResponse from the API
    /// - Returns: A WikiArticle with the processed data
    private func createArticleFromSummary(_ response: WikipediaDetailResponse) -> WikiArticle {
        let dateFormatter = ISO8601DateFormatter()
        let lastModified = response.lastmodified.flatMap { dateFormatter.date(from: $0) }
        
        return WikiArticle(
            id: response.id,
            title: response.title,
            extract: response.extract,
            content: "",
            thumbnail: response.thumbnail?.source,
            url: response.content_urls.mobile.page,
            lastModified: lastModified
        )
    }
}

// MARK: - API Response Models

/// Response model for Wikipedia content URLs
struct ContentURLs: Codable {
    let mobile: MobileURL
}

/// Response model for mobile Wikipedia URLs
struct MobileURL: Codable {
    let page: URL
}
