//
//  ContentView.swift
//  Riki
//
//  Created by Manik on 5/1/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var viewModel = WikiViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Solid background based on system appearance
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main content area
                    ZStack {
                        if viewModel.isLoading {
                            LoadingView()
                                .transition(.opacity.combined(with: .scale))
                        } else if let error = viewModel.error {
                            ErrorView(error: error) {
                                Task {
                                    await viewModel.fetchRandomArticle()
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else if let article = viewModel.article {
                            ArticleView(article: article)
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.error)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.article?.id)
                    
                    // Bottom action area
                    VStack(spacing: 12) {
                        Divider()
                        
                        Button(action: {
                            Task {
                                await viewModel.fetchRandomArticle()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "shuffle")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Discover New Article")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                            .scaleEffect(viewModel.isLoading ? 0.95 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: viewModel.isLoading)
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal, 20)
                        .accessibilityLabel("Fetch new random Wikipedia article")
                    }
                    .padding(.bottom, 8)
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle(viewModel.article?.title ?? "Riki")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let article = viewModel.article {
                        ShareLink(item: article.url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Share article")
                    }
                }
            }
        }
        .task {
            await viewModel.fetchRandomArticle()
        }
        .refreshable {
            await viewModel.fetchRandomArticle()
        }
    }
}

// MARK: - Article View
struct ArticleView: View {
    let article: WikiArticle
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    // Article header
                    ArticleHeaderView(article: article)
                        .id("header")
                    
                    // Article content
                    ArticleContentView(article: article)
                        .padding(.horizontal, 16)
                    
                    // Footer with source link
                    ArticleFooterView(article: article)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                }
            }
            .scrollIndicators(.visible)
        }
    }
}

// MARK: - Article Header View
struct ArticleHeaderView: View {
    let article: WikiArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let thumbnailURL = article.thumbnail {
                AsyncImage(url: thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 250)
                        .clipped()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(maxWidth: .infinity, maxHeight: 250)
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.2)
                        )
                }
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 8) // Small padding above the header image
            }
            
            // Article metadata
            if let lastModified = article.lastModified {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("Updated \(lastModified, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Article Content View
struct ArticleContentView: View {
    let article: WikiArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Extract/Summary
            if !article.extract.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    FormattedTextView(text: article.extract, fontSize: 17, lineSpacing: 8)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                }
            }
            
            // Article sections
            if !article.sections.isEmpty {
                Divider()
                
                ForEach(article.sections) { section in
                    ArticleSectionView(section: section)
                }
            }
        }
    }
}

// MARK: - Article Section View
struct ArticleSectionView: View {
    let section: ArticleSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !section.title.isEmpty {
                Text(section.title)
                    .font(fontForLevel(section.level))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.top, section.level <= 2 ? 16 : 8)
            }
            
            if !section.content.isEmpty {
                FormattedTextView(
                    text: section.content,
                    fontSize: 16,
                    lineSpacing: 6
                )
            }
        }
    }
    
    private func fontForLevel(_ level: Int) -> Font {
        switch level {
        case 1: return .largeTitle
        case 2: return .title
        case 3: return .title2
        case 4: return .title3
        case 5: return .headline
        case 6: return .subheadline
        default: return .body
        }
    }
}

// MARK: - Article Footer View
struct ArticleFooterView: View {
    let article: WikiArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            
            Link(destination: article.url) {
                HStack {
                    Image(systemName: "safari")
                        .foregroundColor(.blue)
                    Text("Read full article on Wikipedia")
                        .foregroundColor(.blue)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.05))
                        )
                )
            }
            .accessibilityLabel("Open full article in Wikipedia")
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let error: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Oops! Something went wrong")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: retryAction) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                )
            }
            .accessibilityLabel("Retry loading article")
        }
        .padding()
    }
}

// MARK: - ViewModel
@MainActor
class WikiViewModel: ObservableObject {
    @Published var article: WikiArticle?
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchRandomArticle() async {
        isLoading = true
        error = nil
        article = nil
        
        do {
            let fetchedArticle = try await WikipediaService.shared.fetchRandomArticle()
            
            // Process article content for better display
            let processedArticle = await processArticleContent(fetchedArticle)
            
            self.article = processedArticle
            self.isLoading = false
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }
    
    // Process and enhance article content for better display
    private func processArticleContent(_ article: WikiArticle) async -> WikiArticle {
        // If no sections were parsed, try to create some based on paragraphs
        if article.sections.isEmpty && !article.content.isEmpty {
            let paragraphs = article.content.components(separatedBy: "\n\n")
            var processedSections: [ArticleSection] = []
            
            for paragraph in paragraphs {
                let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    processedSections.append(ArticleSection(
                        title: "",
                        level: 0,
                        content: trimmed
                    ))
                }
            }
            
            if !processedSections.isEmpty {
                return WikiArticle(
                    id: article.id,
                    title: article.title,
                    extract: article.extract,
                    content: article.content,
                    thumbnail: article.thumbnail,
                    url: article.url,
                    lastModified: article.lastModified,
                    sections: processedSections
                )
            }
        }
        
        return article
    }
}

#Preview {
    ContentView()
}
