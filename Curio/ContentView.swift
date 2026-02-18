//
//  ContentView.swift
//  Curio
//
//  Created by Manik on 5/1/25.
//

import SwiftUI
import SwiftData
import Combine

/// Main content view that displays Wikipedia articles in a full-screen scrollable format
struct ContentView: View {
    @StateObject private var viewModel = WikipediaFeedViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var bookmarkManager: BookmarkManager?
    @State private var showingBookmarks = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.all)

            if let bookmarkManager {
                VerticalArticleFeedView(viewModel: viewModel, bookmarkManager: bookmarkManager)
            }
        }
        .overlay(alignment: .topTrailing) {
            Menu {
                Button {
                    showingBookmarks = true
                } label: {
                    Label("Bookmarks", systemImage: "bookmark")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(12)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .padding(.trailing, 16)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showingBookmarks) {
            BookmarksView()
        }
        .task {
            bookmarkManager = BookmarkManager(modelContext: modelContext)
            await viewModel.loadInitialArticles()
        }
    }
}

// MARK: - Vertical Article Feed View

/// A vertical scrolling view that displays Wikipedia articles in a paginated format
struct VerticalArticleFeedView: View {
    @ObservedObject var viewModel: WikipediaFeedViewModel
    var bookmarkManager: BookmarkManager
    @State private var currentArticleIndex = 0

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.articles.enumerated()), id: \.element.id) { index, article in
                            ArticleCardView(
                                article: article,
                                isCurrentlyVisible: abs(index - currentArticleIndex) <= 1,
                                screenSize: geometry.size,
                                bookmarkManager: bookmarkManager
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .id(index)
                            .onAppear {
                                // Load more articles when approaching the end
                                let shouldLoadMore = index >= viewModel.articles.count - Constants.loadMoreThreshold &&
                                                   !viewModel.isLoading &&
                                                   viewModel.articles.count > 0
                                
                                if shouldLoadMore {
                                    Task {
                                        await viewModel.loadMoreArticles()
                                    }
                                }
                            }
                        }
                        
                        if viewModel.isLoading {
                            LoadingCardView()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                }
                .scrollTargetBehavior(.paging)
            }
        }
        .ignoresSafeArea(.all)
    }

}

// MARK: - Constants

private enum Constants {
    static let minimumArticlesBeforeLoading = 3
    static let loadMoreThreshold = 1 
    static let initialArticleCount = 5
    static let additionalArticleCount = 3
    static let contentHorizontalPadding: CGFloat = 20
    static let contentBottomPadding: CGFloat = 60
    static let buttonCornerRadius: CGFloat = 16
    static let buttonHorizontalPadding: CGFloat = 16
    static let buttonVerticalPadding: CGFloat = 8
}

// MARK: - Article Card View

/// A full-screen card view that displays a Wikipedia article.
/// Uses fullscreen background image for high-res images, or a compact card layout for low-res/no images.
struct ArticleCardView: View {
    let article: WikiArticle
    let isCurrentlyVisible: Bool
    let screenSize: CGSize
    var bookmarkManager: BookmarkManager
    @State private var isPresentingFullArticle = false

    private var useFullscreenLayout: Bool {
        article.hasThumbnail && article.isHighResImage
    }

    var body: some View {
        Group {
            if useFullscreenLayout {
                fullscreenLayout
            } else {
                compactCardLayout
            }
        }
        .sheet(isPresented: $isPresentingFullArticle) {
            ArticleWebViewSheet(url: article.url, title: article.title)
        }
    }

    // MARK: - Fullscreen Layout (high-res images)

    private var fullscreenLayout: some View {
        ZStack(alignment: .bottomLeading) {
            if let thumbnailURL = article.thumbnail {
                AsyncImage(url: thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: screenSize.width, height: screenSize.height)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: screenSize.width, height: screenSize.height)
                        .overlay(ProgressView().tint(.white))
                }
            }

            // Dark gradient for text readability
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: screenSize.width, height: screenSize.height)

            // Content pinned to bottom
            VStack(alignment: .leading, spacing: 12) {
                articleTitleView
                if article.hasContent { articleSummaryView }
                readMoreButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constants.contentHorizontalPadding)
            .padding(.bottom, Constants.contentBottomPadding)
        }
    }

    // MARK: - Compact Card Layout (low-res / no image)

    private var compactCardLayout: some View {
        ZStack {
            // Blurred background from the same image (Apple Music style)
            if let thumbnailURL = article.thumbnail {
                AsyncImage(url: thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: screenSize.width, height: screenSize.height)
                        .clipped()
                        .blur(radius: 70)
                        .scaleEffect(1.2) // prevent blur edge artifacts
                        .overlay(Color.black.opacity(0.4))
                } placeholder: {
                    Color.black
                }
            } else {
                Color.black
            }

            VStack(spacing: 0) {
                // Image centered between safe area top and text
                if let thumbnailURL = article.thumbnail {
                    Spacer()

                    AsyncImage(url: thumbnailURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .frame(maxWidth: screenSize.width - (Constants.contentHorizontalPadding * 2))
                            .frame(maxHeight: screenSize.height * 0.35)
                    } placeholder: {
                        ProgressView()
                            .tint(.white)
                            .frame(height: 200)
                    }

                    Spacer()
                } else {
                    Spacer()
                }

                // Text + button pinned at bottom
                VStack(alignment: .leading, spacing: 12) {
                    articleTitleView
                    if article.hasContent { articleSummaryView }
                    readMoreButton
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Constants.contentHorizontalPadding)
                .padding(.bottom, Constants.contentBottomPadding)
            }
            .padding(.top, 50)
        }
        .clipped()
    }

    // MARK: - Shared Subviews

    private var articleTitleView: some View {
        Text(article.title)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
    }

    private var articleSummaryView: some View {
        Text(article.extract)
            .font(.body)
            .foregroundColor(.white.opacity(0.9))
            .multilineTextAlignment(.leading)
    }

    private var readMoreButton: some View {
        HStack(spacing: 8) {
            Button(action: {
                isPresentingFullArticle = true
            }) {
                HStack(spacing: 8) {
                    Text("Read More")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                        .font(.body)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .glassEffect(.regular.interactive(), in: .capsule)
            }
            .accessibilityLabel("Read full article about \(article.title)")

            ShareLink(item: article.url) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(14)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .accessibilityLabel("Share article about \(article.title)")

            Button {
                bookmarkManager.toggle(article: article)
            } label: {
                Image(systemName: bookmarkManager.isBookmarked(articleId: article.id) ? "bookmark.fill" : "bookmark")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(14)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .accessibilityLabel(bookmarkManager.isBookmarked(articleId: article.id) ? "Remove bookmark for \(article.title)" : "Bookmark \(article.title)")
        }
    }
}

// MARK: - Loading Card View

/// A full-screen loading card displayed while fetching more articles
struct LoadingCardView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
            
            LoadingView()
        }
    }
}

// MARK: - Article WebView Sheet

/// A sheet that presents the full Wikipedia article in Safari with Reader mode
struct ArticleWebViewSheet: View {
    let url: URL
    let title: String

    var body: some View {
        SafariView(url: url)
            .ignoresSafeArea()
    }
}

// MARK: - Wikipedia Feed ViewModel

/// ViewModel that manages the Wikipedia article feed, handling loading and state management
@MainActor
final class WikipediaFeedViewModel: ObservableObject {
    
    @Published var articles: [WikiArticle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let wikipediaService: WikipediaServiceProtocol
    private var lastLoadTriggeredAtIndex = -1
    
    init(wikipediaService: WikipediaServiceProtocol = WikipediaService.shared) {
        self.wikipediaService = wikipediaService
    }
    
    /// Loads the initial batch of articles when the feed is first displayed
    func loadInitialArticles() async {
        guard articles.isEmpty else { return }
        
        await loadArticles(count: Constants.initialArticleCount, isInitialLoad: true)
    }
    
    /// Loads additional articles when the user approaches the end of the current batch
    func loadMoreArticles() async {
        guard !isLoading else { return }
        
        // Prevent duplicate loading for the same trigger point
        let currentTriggerIndex = articles.count - Constants.loadMoreThreshold
        guard currentTriggerIndex > lastLoadTriggeredAtIndex else { return }
        
        lastLoadTriggeredAtIndex = currentTriggerIndex
        await loadArticles(count: Constants.additionalArticleCount, isInitialLoad: false)
    }
    
    /// Loads a specified number of articles
    /// - Parameters:
    ///   - count: Number of articles to load
    ///   - isInitialLoad: Whether this is the initial load (affects error handling)
    private func loadArticles(count: Int, isInitialLoad: Bool) async {
        isLoading = true
        
        if isInitialLoad {
            errorMessage = nil
        }
        
        var loadedCount = 0
        
        for _ in 0..<count {
            do {
                let article = try await wikipediaService.fetchRandomArticle()
                articles.append(article)
                loadedCount += 1
            } catch {
                handleLoadingError(error, isInitialLoad: isInitialLoad, loadedCount: loadedCount)
                break
            }
        }
        
        isLoading = false
        prefetchImages()
    }

    /// Prefetches images for articles that haven't been displayed yet
    private func prefetchImages() {
        let urls = articles.compactMap(\.thumbnail)
        for url in urls {
            guard URLCache.shared.cachedResponse(for: URLRequest(url: url)) == nil else { continue }
            Task.detached(priority: .utility) {
                let request = URLRequest(url: url)
                if let (data, response) = try? await URLSession.shared.data(for: request) {
                    let cached = CachedURLResponse(response: response, data: data)
                    URLCache.shared.storeCachedResponse(cached, for: request)
                }
            }
        }
    }

    /// Handles errors that occur during article loading
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - isInitialLoad: Whether this was during initial loading
    ///   - loadedCount: Number of articles successfully loaded before the error
    private func handleLoadingError(_ error: Error, isInitialLoad: Bool, loadedCount: Int) {
        let errorDescription = error.localizedDescription
        
        if isInitialLoad && loadedCount == 0 {
            // Show error to user only if initial load completely failed
            errorMessage = "Failed to load articles: \(errorDescription)"
        }
        
        // Log all errors for debugging
        print("Failed to load article: \(errorDescription)")
    }
}

#Preview {
    ContentView()
}
