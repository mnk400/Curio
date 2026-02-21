//
//  FeedMode.swift
//  Curio
//
//  Created by Manik on 18/2/26.
//

import Foundation

/// Represents the different article feed modes available in the app
enum FeedMode: Equatable, Hashable {
    /// Random Wikipedia articles (default behavior)
    case random
    /// Paintings and art from curated Wikipedia categories
    case art
    /// Science — astronomy, biology, physics, chemistry, and more
    case science
    /// Articles about places near the user's current location
    case nearby

    /// Display title for use in menus and UI
    var title: String {
        switch self {
        case .random: return "Random"
        case .art: return "Art Mode"
        case .science: return "Science Mode"
        case .nearby: return "Nearby"
        }
    }

    /// SF Symbol name for use in menus and UI
    var systemImage: String {
        switch self {
        case .random: return "shuffle"
        case .art: return "paintpalette"
        case .science: return "atom"
        case .nearby: return "location"
        }
    }

    /// The deepcat search term used by category-based modes, nil for random and nearby
    var deepcatSearchTerm: String? {
        switch self {
        case .random, .nearby: return nil
        case .art: return "deepcat:Paintings"
        case .science: return "deepcat:Science"
        }
    }

    /// Max offset for random pagination in search results
    var deepcatMaxOffset: Int? {
        switch self {
        case .random: return nil
        case .art, .science: return 10_000
        case .nearby: return 500
        }
    }

    /// All category-based modes (excludes .random and .nearby)
    static let categoryModes: [FeedMode] = [.art, .science]

    /// All modes in display order
    static let allModes: [FeedMode] = [.random, .art, .science, .nearby]
}
