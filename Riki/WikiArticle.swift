//
//  WikiArticle.swift
//  Riki
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
    
    /// Full content of the article (currently unused in this implementation)
    let content: String
    
    /// Optional thumbnail image URL for the article
    let thumbnail: URL?
    
    /// URL to the full Wikipedia article
    let url: URL
    
    /// Date when the article was last modified
    let lastModified: Date?
    
    // MARK: - Computed Properties
    
    /// Returns true if the article has extract content to display
    var hasContent: Bool {
        !extract.isEmpty
    }
    
    /// Returns true if the article has a thumbnail image
    var hasThumbnail: Bool {
        thumbnail != nil
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
    let extract_html: String?
    let thumbnail: ThumbnailInfo?
    let content_urls: ContentURLs
    let lastmodified: String?
    
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
    
    /// The aspect ratio of the thumbnail (width/height)
    var aspectRatio: Double {
        Double(width) / Double(height)
    }
    
    /// Returns true if the thumbnail is in landscape orientation
    var isLandscape: Bool {
        aspectRatio > 1.0
    }
    
    /// Returns true if the thumbnail is in portrait orientation
    var isPortrait: Bool {
        aspectRatio < 1.0
    }
    
    /// Returns true if the thumbnail is square
    var isSquare: Bool {
        aspectRatio == 1.0
    }
}