# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is an Xcode-based SwiftUI iOS app targeting **iOS 26.0**. There is no command-line build setup — use Xcode to build and run.

- **Open**: `open Curio.xcodeproj`
- **Run tests**: Cmd+U in Xcode, or `xcodebuild test -scheme Curio -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Bundle ID**: `com.manik.Curio`

## Architecture

MVVM pattern, all in a small set of files:

- **`ContentView.swift`** — Contains the views (`ContentView`, `VerticalArticleFeedView`, `ArticleCardView`, `ArticleWebViewSheet`) AND the `WikipediaFeedViewModel`. This is the main file for UI work.
- **`WikiArticle.swift`** — Data model (`WikiArticle`) and API response Codable structs (`WikipediaDetailResponse`, `ThumbnailInfo`, etc.)
- **`WikipediaService.swift`** — Singleton API client. Fetches random articles from Wikipedia's REST API (`/api/rest_v1/page/random/summary`). Protocol-based for testability.
- **`WebView.swift`** — `SFSafariViewController` wrapper (UIViewControllerRepresentable).
- **`BookmarkArticle.swift`** — SwiftData `@Model` for persisted bookmarks (`articleId`, `title`, `extract`, `thumbnailURL`, `articleURL`, `bookmarkedAt`).
- **`BookmarkManager.swift`** — `@Observable` class wrapping SwiftData operations. Maintains an in-memory `bookmarkedIDs` set for reactive UI updates.
- **`BookmarksView.swift`** — Bookmarks list screen with thumbnail rows, tap-to-open in Safari, swipe-to-delete.
- **`CurioApp.swift`** — App entry point with appearance configuration and SwiftData `.modelContainer`.
- **`AppConfiguration.swift`** — Constants for API, UI, content, and accessibility.
- **`LoadingView.swift`** — Animated loading spinner.

## Key Design Decisions

**Dual image layout**: `ArticleCardView` branches between two layouts based on `WikiArticle.isHighResImage` (both dimensions >= 800px):
- **Fullscreen layout**: High-res image fills screen as background with gradient overlay and text at bottom.
- **Compact card layout**: Low-res image shown at natural size with rounded corners, centered above text. Background is a heavily blurred version of the same image (Apple Music style).

**Image resolution**: The Wikipedia API returns both `thumbnail` (small) and `originalimage` (full res). We prefer `originalimage` and fall back to `thumbnail`. Image dimensions are passed through to the view layer for layout branching.

**Image prefetching**: After each batch of articles loads, images are prefetched into `URLCache` at `.utility` priority so `AsyncImage` displays them instantly when scrolled to.

**Article viewing**: "Read More" opens the Wikipedia mobile page in `SFSafariViewController` (not WKWebView). Share and Bookmark buttons sit alongside it in a liquid glass button row.

**Bookmarks**: Persisted via SwiftData. `BookmarkManager` keeps a `bookmarkedIDs: Set<String>` in sync with the database so the bookmark button icon toggles reactively. The bookmarks screen is accessed from the ellipsis menu (top-right overlay on the feed).

**Overflow menu**: A `Menu` with ellipsis icon in the top-right of the feed. Currently contains Bookmarks; designed to be extended with more items (e.g. Settings).

## Dependencies

No external Swift packages are used at runtime (SwiftSoup is declared in the project but unused). Frameworks: SwiftUI, SwiftData, Combine, SafariServices.
