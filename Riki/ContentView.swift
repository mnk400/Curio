//
//  ContentView.swift
//  Riki
//
//  Created by Manik on 5/1/25.
//

import SwiftUI
import Combine

/// Main content view that displays Wikipedia articles in a full-screen scrollable format
struct ContentView: View {
    @StateObject private var viewModel = WikipediaFeedViewModel()
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.all)
            
            VerticalArticleFeedView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadInitialArticles()
        }
    }
}

// MARK: - Vertical Article Feed View

/// A vertical scrolling view that displays Wikipedia articles in a paginated format
struct VerticalArticleFeedView: View {
    @ObservedObject var viewModel: WikipediaFeedViewModel
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
                                screenSize: geometry.size
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
    static let contentBottomPadding: CGFloat = 100
    static let buttonCornerRadius: CGFloat = 16
    static let buttonHorizontalPadding: CGFloat = 16
    static let buttonVerticalPadding: CGFloat = 8
}

// MARK: - Article Card View

/// A full-screen card view that displays a Wikipedia article with background image and content overlay
struct ArticleCardView: View {
    let article: WikiArticle
    let isCurrentlyVisible: Bool
    let screenSize: CGSize
    @State private var isPresentingFullArticle = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            backgroundImageView
            textReadabilityOverlay
            articleContentOverlay
        }
        .sheet(isPresented: $isPresentingFullArticle) {
            ArticleWebViewSheet(url: article.url, title: article.title)
        }
    }
    
    // MARK: - Private Views
    
    /// Background image view with fallback gradient
    private var backgroundImageView: some View {
        Group {
            if let thumbnailURL = article.thumbnail {
                AsyncImage(url: thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: screenSize.width, height: screenSize.height)
                        .clipped()
                } placeholder: {
                    imagePlaceholder
                }
            } else {
                fallbackGradientBackground
            }
        }
    }
    
    /// Placeholder view shown while image is loading
    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: screenSize.width, height: screenSize.height)
            .overlay(
                ProgressView()
                    .tint(.white)
            )
    }
    
    /// Fallback gradient background when no image is available
    private var fallbackGradientBackground: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: screenSize.width, height: screenSize.height)
    }
    
    /// Dark overlay to improve text readability
    private var textReadabilityOverlay: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.8)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )
            .frame(width: screenSize.width, height: screenSize.height)
    }
    
    /// Article content overlay positioned at the bottom
    private var articleContentOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            articleTitleView
            
            if article.hasContent {
                articleSummaryView
            }
            
            readMoreButton
        }
        .padding(.horizontal, Constants.contentHorizontalPadding)
        .padding(.bottom, Constants.contentBottomPadding)
        .frame(maxWidth: screenSize.width - (Constants.contentHorizontalPadding * 2))
    }
    
    /// Article title view
    private var articleTitleView: some View {
        Text(article.title)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
    }
    
    /// Article summary/extract view
    private var articleSummaryView: some View {
        Text(article.extract)
            .font(.body)
            .foregroundColor(.white.opacity(0.9))
            .lineLimit(3)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
    }
    
    /// Button to open the full article
    private var readMoreButton: some View {
        Button(action: {
            isPresentingFullArticle = true
        }) {
            HStack(spacing: 8) {
                Text("Read More")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Image(systemName: "arrow.right")
                    .font(.caption)
            }
            .foregroundColor(.black)
            .padding(.horizontal, Constants.buttonHorizontalPadding)
            .padding(.vertical, Constants.buttonVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: Constants.buttonCornerRadius)
                    .fill(Color.white)
            )
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .accessibilityLabel("Read full article about \(article.title)")
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

/// A sheet that presents the full Wikipedia article in a web view
struct ArticleWebViewSheet: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            WebView(url: url)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Share article")
                    }
                }
        }
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
