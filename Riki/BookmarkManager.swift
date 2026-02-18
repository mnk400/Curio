import Foundation
import SwiftData

@Observable
final class BookmarkManager {
    private let modelContext: ModelContext
    private(set) var bookmarkedIDs: Set<String> = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadBookmarkedIDs()
    }

    func isBookmarked(articleId: String) -> Bool {
        bookmarkedIDs.contains(articleId)
    }

    func toggle(article: WikiArticle) {
        if let existing = fetchBookmark(articleId: article.id) {
            modelContext.delete(existing)
            bookmarkedIDs.remove(article.id)
        } else {
            let bookmark = BookmarkArticle(
                articleId: article.id,
                title: article.title,
                extract: article.extract,
                thumbnailURL: article.thumbnail,
                articleURL: article.url
            )
            modelContext.insert(bookmark)
            bookmarkedIDs.insert(article.id)
        }
        try? modelContext.save()
    }

    func delete(_ bookmark: BookmarkArticle) {
        bookmarkedIDs.remove(bookmark.articleId)
        modelContext.delete(bookmark)
        try? modelContext.save()
    }

    private func loadBookmarkedIDs() {
        let descriptor = FetchDescriptor<BookmarkArticle>()
        let bookmarks = (try? modelContext.fetch(descriptor)) ?? []
        bookmarkedIDs = Set(bookmarks.map(\.articleId))
    }

    private func fetchBookmark(articleId: String) -> BookmarkArticle? {
        let predicate = #Predicate<BookmarkArticle> { $0.articleId == articleId }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try? modelContext.fetch(descriptor).first
    }
}
