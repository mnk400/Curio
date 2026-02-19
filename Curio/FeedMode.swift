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

    /// Display title for use in menus and UI
    var title: String {
        switch self {
        case .random: return "Random"
        case .art: return "Art Mode"
        case .science: return "Science Mode"
        }
    }

    /// SF Symbol name for use in menus and UI
    var systemImage: String {
        switch self {
        case .random: return "shuffle"
        case .art: return "paintpalette"
        case .science: return "atom"
        }
    }

    /// The deepcat search term used by category-based modes, nil for random
    var deepcatSearchTerm: String? {
        switch self {
        case .random: return nil
        case .art: return "deepcat:Paintings"
        case .science: return "deepcat:Science"
        }
    }

    /// Max offset for random pagination (Wikipedia search API caps at 10,000)
    var deepcatMaxOffset: Int? {
        switch self {
        case .random: return nil
        case .art: return 10_000
        case .science: return 10_000
        }
    }

    /// All category-based modes (excludes .random)
    static let categoryModes: [FeedMode] = [.art, .science]

    /// All modes in display order
    static let allModes: [FeedMode] = [.random, .art, .science]
}
