//
//  AppConfiguration.swift
//  Curio
//
//  Created by Manik on 5/1/25.
//

import SwiftUI

enum AppConfiguration {
    /// Shared layout values used by ArticleCardView
    enum UI {
        /// Horizontal padding for article text and buttons
        static let contentHorizontalPadding: CGFloat = 20
        /// Bottom padding to keep content above the home indicator
        static let contentBottomPadding: CGFloat = 60
    }

    /// Article feed loading behaviour
    enum Content {
        /// Number of articles fetched on first launch
        static let initialArticleCount = 5
        /// Number of articles fetched when scrolling near the end
        static let additionalArticleCount = 3
        /// How many articles from the end triggers the next fetch
        static let loadMoreThreshold = 1
    }
}
