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

    private func loadArticles(count: Int) async {
        isLoading = true

        for _ in 0..<count {
            do {
                let article = try await wikipediaService.fetchRandomArticle()
                articles.append(article)
            } catch {
                print("Failed to load article: \(error.localizedDescription)")
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
