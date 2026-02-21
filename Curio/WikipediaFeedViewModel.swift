//
//  WikipediaFeedViewModel.swift
//  Curio
//
//  Created by Manik on 17/2/26.
//

import SwiftUI
import CoreLocation

/// ViewModel that manages the Wikipedia article feed, handling loading and state management
@MainActor
final class WikipediaFeedViewModel: ObservableObject {

    @Published var articles: [WikiArticle] = []
    @Published var isLoading = false
    @Published var feedMode: FeedMode = .random
    @Published var errorMessage: String?

    private let wikipediaService: WikipediaServiceProtocol
    private var lastLoadTriggeredAtIndex = -1
    private let locationManager = LocationManager()

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
            if mode == .nearby {
                await setupNearbyAndLoad()
            } else {
                await loadArticles(count: AppConfiguration.Content.initialArticleCount)
            }
        }
    }

    /// Requests the user's location and passes it to the service before loading nearby articles
    private func setupNearbyAndLoad() async {
        isLoading = true
        errorMessage = nil

        do {
            let coordinate = try await locationManager.requestLocation()
            if let service = wikipediaService as? WikipediaService {
                service.setUserLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            }
            await loadArticles(count: AppConfiguration.Content.initialArticleCount)
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    /// Retries loading articles after an error
    func retry() {
        errorMessage = nil
        Task {
            if feedMode == .nearby {
                await setupNearbyAndLoad()
            } else {
                await loadArticles(count: AppConfiguration.Content.initialArticleCount)
            }
        }
    }

    private func loadArticles(count: Int) async {
        isLoading = true
        errorMessage = nil

        for _ in 0..<count {
            do {
                let article = try await wikipediaService.fetchArticle(for: feedMode)
                articles.append(article)
                prefetchImage(for: article)
            } catch {
                print("Failed to load article: \(error.localizedDescription)")
                if articles.isEmpty {
                    errorMessage = error.localizedDescription
                }
                break
            }
        }

        isLoading = false
    }

    /// Prefetches a single article's image into URLCache in the background
    private func prefetchImage(for article: WikiArticle) {
        guard let url = article.thumbnail else { return }
        let request = URLRequest(url: url)
        guard URLCache.shared.cachedResponse(for: request) == nil else { return }
        Task.detached(priority: .utility) {
            if let (data, response) = try? await URLSession.shared.data(for: request) {
                let cached = CachedURLResponse(response: response, data: data)
                URLCache.shared.storeCachedResponse(cached, for: request)
            }
        }
    }
}
