//
//  WikipediaService.swift
//  Curio
//
//  Created by Manik on 5/1/25.
//

import Foundation

// MARK: - Wikipedia Service Protocol

/// Protocol defining the interface for Wikipedia article fetching
protocol WikipediaServiceProtocol {
    /// Fetches an article appropriate for the given feed mode
    /// - Parameter mode: The feed mode determining how articles are sourced
    /// - Returns: A WikiArticle containing the article data
    /// - Throws: WikipediaError if the request fails
    func fetchArticle(for mode: FeedMode) async throws -> WikiArticle

    /// Resets any cached state for mode-specific fetching (e.g. title buffers)
    func resetModeState()
}

// MARK: - Wikipedia Errors

/// Errors that can occur when fetching Wikipedia articles
enum WikipediaError: LocalizedError {
    case invalidURL
    case noData
    case parsingError(String)
    case networkError(Error)
    case httpError(statusCode: Int)
    case articleNotFound
    case noSearchResults(mode: FeedMode)
    case noArticlesWithImages(mode: FeedMode, tried: Int)

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
        case .httpError(let statusCode):
            return "Wikipedia returned HTTP \(statusCode)"
        case .articleNotFound:
            return "Article not found"
        case .noSearchResults(let mode):
            return "No \(mode.title) articles found. Try a different mode."
        case .noArticlesWithImages(let mode, let tried):
            return "Checked \(tried) \(mode.title) articles but none had images. Try again."
        }
    }
}

// MARK: - Wikipedia Service

/// Service responsible for fetching Wikipedia articles from the Wikipedia API
final class WikipediaService: WikipediaServiceProtocol {

    static let shared = WikipediaService()

    private let urlSession: URLSession
    private let jsonDecoder: JSONDecoder

    /// Title buffers keyed by feed mode for category-based feeds
    private var titleBuffers: [FeedMode: [String]] = [:]

    /// User's current location for nearby article fetching
    private(set) var userCoordinate: (latitude: Double, longitude: Double)?

    private enum APIConstants {
        static let randomSummaryURL = "https://en.wikipedia.org/api/rest_v1/page/random/summary"
        static let summaryBaseURL = "https://en.wikipedia.org/api/rest_v1/page/summary/"
        static let searchAPIBaseURL = "https://en.wikipedia.org/w/api.php"
        static let requestTimeout: TimeInterval = 60
        static let resourceTimeout: TimeInterval = 120
    }

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConstants.requestTimeout
        configuration.timeoutIntervalForResource = APIConstants.resourceTimeout
        configuration.waitsForConnectivity = true

        self.urlSession = URLSession(configuration: configuration)
        self.jsonDecoder = JSONDecoder()
    }

    /// Sets the user's current location for nearby article fetching
    func setUserLocation(latitude: Double, longitude: Double) {
        userCoordinate = (latitude: latitude, longitude: longitude)
    }

    /// Fetches an article appropriate for the given feed mode
    func fetchArticle(for mode: FeedMode) async throws -> WikiArticle {
        switch mode {
        case .random:
            return try await fetchRandomArticle()
        default:
            return try await fetchSearchArticle(for: mode)
        }
    }

    /// Resets cached state for mode-specific fetching
    func resetModeState() {
        titleBuffers.removeAll()
    }

    // MARK: - Random Feed

    /// Fetches a random Wikipedia article
    private func fetchRandomArticle() async throws -> WikiArticle {
        guard let url = URL(string: APIConstants.randomSummaryURL) else {
            throw WikipediaError.invalidURL
        }

        do {
            let (data, response) = try await urlSession.data(from: url)

            try validateHTTPResponse(response)
            try validateResponseData(data)

            let summary = try jsonDecoder.decode(WikipediaDetailResponse.self, from: data)
            return articleFromSummary(summary)

        } catch let decodingError as DecodingError {
            throw WikipediaError.parsingError("Failed to decode summary: \(decodingError.localizedDescription)")
        } catch let wikipediaError as WikipediaError {
            throw wikipediaError
        } catch {
            throw WikipediaError.networkError(error)
        }
    }
    
    // MARK: - Search-Based Feeds (DeepCat & Nearby)

    /// Fetches an article from a search-based feed mode, using a per-mode title buffer.
    /// Tries all titles in the buffer before giving up — the buffer is already bounded by `searchBatchSize`.
    private func fetchSearchArticle(for mode: FeedMode) async throws -> WikiArticle {
        if titleBuffers[mode, default: []].isEmpty {
            try await refillTitleBuffer(for: mode)
        }

        guard titleBuffers[mode]?.isEmpty == false else {
            throw WikipediaError.noSearchResults(mode: mode)
        }

        var triedCount = 0
        var lastError: Error?

        while titleBuffers[mode]?.isEmpty == false {
            let title = titleBuffers[mode]!.removeFirst()
            triedCount += 1
            do {
                let article = try await fetchArticle(titled: title)
                let wikiArticle = articleFromSummary(article)
                if wikiArticle.hasThumbnail {
                    return wikiArticle
                }
            } catch {
                lastError = error
                continue
            }
        }

        throw lastError ?? WikipediaError.noArticlesWithImages(mode: mode, tried: triedCount)
    }

    /// Resolves the search term for a given mode
    private func searchTerm(for mode: FeedMode) -> String? {
        if let deepcat = mode.deepcatSearchTerm {
            return deepcat
        }
        if mode == .nearby, let coord = userCoordinate {
            return "nearcoord:50km,\(coord.latitude),\(coord.longitude)"
        }
        return nil
    }

    /// Refills the title buffer for a given mode using its search term (with retry)
    /// Retries with progressively smaller offsets if the search returns no results
    private func refillTitleBuffer(for mode: FeedMode) async throws {
        guard let searchTerm = searchTerm(for: mode),
              let maxOffset = mode.deepcatMaxOffset else { return }

        let batchSize = AppConfiguration.DeepCat.searchBatchSize
        let maxAttempts = AppConfiguration.DeepCat.maxRetries
        var effectiveMaxOffset = maxOffset

        for attempt in 1...maxAttempts {
            let randomOffset = Int.random(in: 0..<max(1, effectiveMaxOffset - batchSize))
            print("[\(mode.title)] search attempt \(attempt)/\(maxAttempts), offset=\(randomOffset) (max=\(effectiveMaxOffset))")

            var components = URLComponents(string: APIConstants.searchAPIBaseURL)!
            components.queryItems = [
                URLQueryItem(name: "action", value: "query"),
                URLQueryItem(name: "list", value: "search"),
                URLQueryItem(name: "srsearch", value: searchTerm),
                URLQueryItem(name: "srnamespace", value: "0"),
                URLQueryItem(name: "srlimit", value: String(batchSize)),
                URLQueryItem(name: "sroffset", value: String(randomOffset)),
                URLQueryItem(name: "format", value: "json"),
            ]

            guard let url = components.url else {
                throw WikipediaError.invalidURL
            }

            do {
                let (data, response) = try await urlSession.data(from: url)
                try validateHTTPResponse(response)
                try validateResponseData(data)

                let result = try jsonDecoder.decode(DeepCatSearchResponse.self, from: data)
                let titles = result.query.search.map(\.title)

                if !titles.isEmpty {
                    titleBuffers[mode] = titles.shuffled()
                    return
                }

                // Empty results — offset likely overshot, shrink range and retry
                effectiveMaxOffset = max(batchSize, effectiveMaxOffset / 4)
                print("[\(mode.title)] empty results, reducing max offset to \(effectiveMaxOffset)")

                if attempt == maxAttempts {
                    throw WikipediaError.noSearchResults(mode: mode)
                }
            } catch let error as WikipediaError {
                if attempt == maxAttempts { throw error }
                try await Task.sleep(for: .seconds(1))
            } catch {
                if attempt == maxAttempts {
                    throw WikipediaError.networkError(error)
                }
                try await Task.sleep(for: .seconds(1))
            }
        }
    }

    /// Fetches an article by its Wikipedia title
    private func fetchArticle(titled title: String) async throws -> WikipediaDetailResponse {
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
        guard let url = URL(string: APIConstants.summaryBaseURL + encodedTitle) else {
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
    
    // MARK: - Helpers

    /// Validates the HTTP response from the Wikipedia API
    /// - Parameter response: The URLResponse to validate
    /// - Throws: WikipediaError.networkError if the response is invalid
    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WikipediaError.networkError(URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            throw WikipediaError.httpError(statusCode: httpResponse.statusCode)
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

    /// Converts an API summary response into a WikiArticle
    private func articleFromSummary(_ response: WikipediaDetailResponse) -> WikiArticle {
        let bestImage = response.originalimage ?? response.thumbnail

        return WikiArticle(
            id: response.id,
            title: response.title,
            extract: response.extract,
            thumbnail: bestImage?.source,
            imageWidth: bestImage?.width,
            imageHeight: bestImage?.height,
            url: response.content_urls.mobile.page
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
