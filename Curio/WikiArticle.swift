//
//  WikiArticle.swift
//  Curio
//
//  Created by Manik on 5/1/25.
//

import Foundation

// MARK: - WikiArticle Model

/// Represents a Wikipedia article with its essential information
struct WikiArticle: Identifiable, Equatable {

    /// Unique identifier for the article
    let id: String

    /// The title of the Wikipedia article
    let title: String

    /// A brief extract/summary of the article content
    let extract: String

    /// Optional thumbnail image URL for the article
    let thumbnail: URL?

    /// Image dimensions in pixels (from the API response)
    let imageWidth: Int?
    let imageHeight: Int?

    /// URL to the full Wikipedia article
    let url: URL

    // MARK: - Constants

    /// Minimum pixel dimension to qualify for fullscreen layout
    private static let fullscreenMinDimension = 800

    // MARK: - Computed Properties

    /// Returns true if the article has extract content to display
    var hasContent: Bool {
        !extract.isEmpty
    }

    /// Returns true if the article has a thumbnail image
    var hasThumbnail: Bool {
        thumbnail != nil
    }

    /// Returns true if the image is high-res enough for fullscreen display
    var isHighResImage: Bool {
        guard let w = imageWidth, let h = imageHeight else { return false }
        return w >= Self.fullscreenMinDimension && h >= Self.fullscreenMinDimension
    }

    static func == (lhs: WikiArticle, rhs: WikiArticle) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - API Response Models

/// Response model for Wikipedia article detail API calls
struct WikipediaDetailResponse: Codable {
    let pageid: Int
    let title: String
    let extract: String
    let thumbnail: ThumbnailInfo?
    let originalimage: ThumbnailInfo?
    let content_urls: ContentURLs

    /// Computed property to convert pageid to string for use as identifier
    var id: String {
        String(pageid)
    }
}

/// Information about the article's thumbnail image
struct ThumbnailInfo: Codable {
    let source: URL
    let width: Int
    let height: Int
}

// MARK: - Search API Response Models (MediaWiki Action API)

/// Top-level response from the MediaWiki `action=query&list=search` endpoint
struct DeepCatSearchResponse: Codable {
    let query: DeepCatSearchQuery
}

/// Query result containing the search results
struct DeepCatSearchQuery: Codable {
    let search: [DeepCatSearchResult]
}

/// A single search result from the deepcat query
struct DeepCatSearchResult: Codable {
    let pageid: Int
    let title: String
}
