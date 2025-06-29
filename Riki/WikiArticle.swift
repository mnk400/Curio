//
//  WikiArticle.swift
//  Riki
//
//  Created by Manik on 5/1/25.
//

import Foundation

// MARK: - WikiArticle Model
struct WikiArticle: Identifiable, Equatable {
    let id: String
    let title: String
    let extract: String
    let content: String
    let thumbnail: URL?
    let url: URL
    let lastModified: Date?
    let sections: [ArticleSection]
    
    // Computed properties for better UX
    var hasContent: Bool {
        !extract.isEmpty || !sections.isEmpty
    }
    
    var readingTimeEstimate: Int {
        let wordCount = sections.reduce(extract.split(separator: " ").count) { count, section in
            count + section.content.split(separator: " ").count
        }
        return max(1, wordCount / 200) // Average reading speed: 200 words per minute
    }
    
    var formattedLastModified: String? {
        guard let lastModified = lastModified else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastModified, relativeTo: Date())
    }
    
    static func == (lhs: WikiArticle, rhs: WikiArticle) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - ArticleSection Model
struct ArticleSection: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let level: Int
    let content: String
    
    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var wordCount: Int {
        content.split(separator: " ").count
    }
    
    static func == (lhs: ArticleSection, rhs: ArticleSection) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - API Response Models
struct WikipediaDetailResponse: Codable {
    let pageid: Int
    let title: String
    let extract: String
    let extract_html: String?
    let thumbnail: ThumbnailInfo?
    let content_urls: ContentURLs
    let lastmodified: String?
    
    var id: String {
        String(pageid)
    }
}

struct ThumbnailInfo: Codable {
    let source: URL
    let width: Int
    let height: Int
    
    var aspectRatio: Double {
        Double(width) / Double(height)
    }
    
    var isLandscape: Bool {
        aspectRatio > 1.0
    }
}