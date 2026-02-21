//
//  ArticleCardView.swift
//  Curio
//
//  Created by Manik on 17/2/26.
//

import SwiftUI

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
            .padding(.horizontal, AppConfiguration.UI.contentHorizontalPadding)
            .padding(.bottom, AppConfiguration.UI.contentBottomPadding)
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
                LinearGradient(
                    colors: [Color.gray.opacity(0.3), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
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
                            .frame(maxWidth: screenSize.width - (AppConfiguration.UI.contentHorizontalPadding * 2))
                            .frame(maxHeight: screenSize.height * 0.35)
                    } placeholder: {
                        ProgressView()
                            .tint(.white)
                            .frame(height: 200)
                    }

                    Spacer()
                } else {
                    Spacer()
                    Text("No image available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                // Text + button pinned at bottom
                VStack(alignment: .leading, spacing: 12) {
                    articleTitleView
                    if article.hasContent { articleSummaryView }
                    readMoreButton
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppConfiguration.UI.contentHorizontalPadding)
                .padding(.bottom, AppConfiguration.UI.contentBottomPadding)
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
        .environment(\.colorScheme, .dark)
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
