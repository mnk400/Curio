//
//  WikiArticle.swift
//  Riki
//
//  Created by Manik on 5/1/25.
//

import Foundation

struct WikiArticle: Identifiable {
    let id: String
    let title: String
    let extract: String
    let content: String
    let thumbnail: URL?
    let url: URL
    
    let lastModified: Date?
    
    var sections: [ArticleSection] = []
}

struct ArticleSection: Identifiable {
    let id = UUID()
    let title: String
    let level: Int
    let content: String
}

struct WikipediaDetailResponse: Codable {
    let pageid: Int
    let title: String
    let extract: String
    let extract_html: String?
    let thumbnail: ThumbnailInfo?
    let content_urls: ContentURLs
    let lastmodified: String?
    
    var id: String {
        return String(pageid)
    }
}

struct ThumbnailInfo: Codable {
    let source: URL
    let width: Int
    let height: Int
}