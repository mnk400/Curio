//
//  WikipediaFeedViewModel.swift
//  Curio
//
//  Created by Manik on 17/2/26.
//

import SwiftUI

/// ViewModel that manages the Wikipedia article feed, handling loading and state management
@MainActor
final class WikipediaFeedViewModel: ObservableObject {

    @Published var articles: [WikiArticle] = []
    @Published var isLoading = false
    @Published var feedMode: FeedMode = .random
    @Published var errorMessage: String?

    private let wikipediaService: WikipediaServiceProtocol
    private var lastLoadTriggeredAtIndex = -1

    init(wikipediaService: WikipediaServiceProtocol = WikipediaService.shared) {
        self.wikipediaService = wikipediaService
    }

    /// Loads the initial batch of articles when the feed is first displayed
    func loadInitialArticles() async {
        guard articles.isEmpty else { return }

        await loadArticles(count: AppConfiguration.Content.initialArticleCount)
    }

    /// Loads additional articles when the user approaches the end of the current batch
    func loadMoreArticles() async {
        guard !isLoading else { return }

        // Prevent duplicate loading for the same trigger point
        let currentTriggerIndex = articles.count - AppConfiguration.Content.loadMoreThreshold
        guard currentTriggerIndex > lastLoadTriggeredAtIndex else { return }

        lastLoadTriggeredAtIndex = currentTriggerIndex
        await loadArticles(count: AppConfiguration.Content.additionalArticleCount)
    }

    /// Switches the feed to a new mode, clearing existing articles and reloading
    func setFeedMode(_ mode: FeedMode) {
        guard mode != feedMode else { return }
        feedMode = mode
        articles.removeAll()
        lastLoadTriggeredAtIndex = -1
        wikipediaService.resetModeState()

        Task {
            await loadArticles(count: AppConfiguration.Content.initialArticleCount)
        }
    }

    /// Retries loading articles after an error
    func retry() {
        errorMessage = nil
        Task {
            await loadArticles(count: AppConfiguration.Content.initialArticleCount)
        }
    }

    private func loadArticles(count: Int) async {
        isLoading = true
        errorMessage = nil

        for _ in 0..<count {
            do {
                let article = try await wikipediaService.fetchArticle(for: feedMode)
                articles.append(article)
            } catch {
                print("Failed to load article: \(error.localizedDescription)")
                if articles.isEmpty {
                    errorMessage = "Failed to load articles. Please try again."
                }
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
}
