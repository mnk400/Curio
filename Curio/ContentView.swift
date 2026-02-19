//
//  ContentView.swift
//  Curio
//
//  Created by Manik on 5/1/25.
//

import SwiftUI
import SwiftData

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

            if let errorMessage = viewModel.errorMessage, viewModel.articles.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Button {
                        viewModel.retry()
                    } label: {
                        Text("Try Again")
                            .fontWeight(.medium)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .glassEffect(.regular.interactive(), in: .capsule)
                    }
                }
            } else if let bookmarkManager {
                VerticalArticleFeedView(viewModel: viewModel, bookmarkManager: bookmarkManager)
            }
        }
        .overlay(alignment: .topTrailing) {
            Menu {
                ForEach(FeedMode.allModes, id: \.self) { mode in
                    Toggle(isOn: Binding(
                        get: { viewModel.feedMode == mode },
                        set: { if $0 { viewModel.setFeedMode(mode) } }
                    )) {
                        Label(mode.title, systemImage: mode.systemImage)
                    }
                }

                Divider()

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
                                let shouldLoadMore = index >= viewModel.articles.count - AppConfiguration.Content.loadMoreThreshold &&
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

#Preview {
    ContentView()
}
