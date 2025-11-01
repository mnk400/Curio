//
//  AppConfiguration.swift
//  Riki
//
//  Created by Manik on 5/1/25.
//

import Foundation
import SwiftUI

// MARK: - App Configuration
enum AppConfiguration {
    enum API {
        static let baseURL = "https://en.wikipedia.org"
        static let randomSummaryEndpoint = "/api/rest_v1/page/random/summary"
        static let parseEndpoint = "/w/api.php"
        static let requestTimeout: TimeInterval = 30
        static let resourceTimeout: TimeInterval = 60
    }
    
    enum UI {
        static let defaultFontSize: CGFloat = 16
        static let defaultLineSpacing: CGFloat = 6
        static let animationDuration: Double = 0.3
        static let buttonHeight: CGFloat = 50
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 2
        static let maxImageHeight: CGFloat = 250
    }
    
    enum Content {
        static let averageReadingSpeed = 200 // words per minute
        static let maxSectionsToDisplay = 20
        static let maxTableRows = 50
        static let maxTableColumns = 10
    }
    
    enum Accessibility {
        static let minimumTapTargetSize: CGFloat = 44
        static let preferredContentSizeCategory = ContentSizeCategory.large
    }
}

// MARK: - App Theme
enum AppTheme {
    enum Colors {
        static let primary = Color.blue
        static let secondary = Color.gray
        static let accent = Color.orange
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.systemGray6)
        static let error = Color.red
        static let success = Color.green
        static let warning = Color.orange
    }
    
    enum Gradients {
        // Keeping for backward compatibility but using solid colors
        static let primaryButton = Color.blue
        static let backgroundGradient = Color(.systemBackground)
        static let imageOverlay = Color.clear
    }
    
    enum Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let headline = Font.headline.weight(.medium)
        static let body = Font.body
        static let caption = Font.caption
        static let footnote = Font.footnote
    }
}

enum AppConstants {
    static let appName = "Riki"
    static let appVersion = "1.0.0"
    static let wikipediaAttribution = "Content from Wikipedia"
    static let githubURL = "https://github.com/mnk400/riki"
    static let supportEmail = "me@manik.cc"
}

// MARK: - Feature Flags
enum FeatureFlags {
    static let enableDarkMode = true
    static let enableShareSheet = true
}
