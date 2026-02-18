import Foundation
import SwiftData

@Model
final class BookmarkArticle {
    @Attribute(.unique) var articleId: String
    var title: String
    var extract: String
    var thumbnailURL: URL?
    var articleURL: URL
    var bookmarkedAt: Date

    init(articleId: String, title: String, extract: String, thumbnailURL: URL?, articleURL: URL, bookmarkedAt: Date = .now) {
        self.articleId = articleId
        self.title = title
        self.extract = extract
        self.thumbnailURL = thumbnailURL
        self.articleURL = articleURL
        self.bookmarkedAt = bookmarkedAt
    }
}
