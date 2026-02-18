import SwiftUI
import SwiftData

struct BookmarksView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BookmarkArticle.bookmarkedAt, order: .reverse) private var bookmarks: [BookmarkArticle]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedURL: URL?

    var body: some View {
        NavigationStack {
            Group {
                if bookmarks.isEmpty {
                    ContentUnavailableView(
                        "No Bookmarks",
                        systemImage: "bookmark",
                        description: Text("Articles you bookmark will appear here.")
                    )
                } else {
                    List {
                        ForEach(bookmarks) { bookmark in
                            Button {
                                selectedURL = bookmark.articleURL
                            } label: {
                                BookmarkRow(bookmark: bookmark)
                            }
                            .tint(.primary)
                            .listRowSeparatorTint(.gray.opacity(0.3))
                        }
                        .onDelete(perform: deleteBookmarks)
                    }
                    .listSectionSeparator(.hidden, edges: .top)
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedURL) { url in
                ArticleWebViewSheet(url: url, title: "")
            }
        }
    }

    private func deleteBookmarks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(bookmarks[index])
        }
        try? modelContext.save()
    }
}

private struct BookmarkRow: View {
    let bookmark: BookmarkArticle

    var body: some View {
        HStack(spacing: 12) {
            if let thumbnailURL = bookmark.thumbnailURL {
                AsyncImage(url: thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(bookmark.title)
                    .font(.headline)
                    .lineLimit(2)

                if !bookmark.extract.isEmpty {
                    Text(bookmark.extract)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
