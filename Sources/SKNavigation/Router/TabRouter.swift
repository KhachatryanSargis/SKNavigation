import SwiftUI
import Observation
import SKCore

// MARK: - Tab Protocol

/// Represents a tab in the application's tab bar.
///
/// Each app defines its own `Tab` enum conforming to this protocol.
///
/// Example:
/// ```swift
/// enum AppTab: String, Tab {
///     case home, search, favorites, profile
///
///     var title: String { rawValue.capitalized }
///     var icon: String {
///         switch self {
///         case .home:      "house"
///         case .search:    "magnifyingglass"
///         case .favorites: "heart"
///         case .profile:   "person.circle"
///         }
///     }
/// }
/// ```
public protocol Tab: Hashable, Identifiable, CaseIterable, Sendable {

    /// The display title for this tab.
    var title: String { get }

    /// The SF Symbol name for this tab's icon.
    var icon: String { get }

    /// The accessibility label for this tab. Defaults to ``title``.
    var accessibilityLabel: String { get }

    /// Optional badge value for this tab.
    var badge: String? { get }
}

extension Tab {
    public var id: Self { self }
    public var accessibilityLabel: String { title }
    public var badge: String? { nil }
}

// MARK: - Tab Router

/// Observable state container for tab-based navigation.
///
/// Manages the currently selected tab and provides utilities for
/// programmatic tab switching, including re-tap-to-root behavior.
@Observable
@MainActor
public final class TabRouter<T: Tab> {

    // MARK: - State

    /// The currently selected tab.
    public private(set) var selectedTab: T

    /// The previously selected tab, useful for transition animations.
    public private(set) var previousTab: T?

    /// Fires when the user taps the already-selected tab.
    /// Coordinators can observe this to pop to root.
    public private(set) var retapCount: Int = 0

    /// Whether the tab bar is currently hidden.
    /// Updated by ``TabCoordinatedView`` based on the active route's ``Route/hidesTabBar``.
    public var isTabBarHidden: Bool = false

    // MARK: - Logging

    private let logger: any LoggerProtocol

    // MARK: - Lifecycle

    public init(
        initialTab: T,
        logger: any LoggerProtocol = OSLogLogger(subsystem: "SKNavigation", category: "TabRouter")
    ) {
        self.selectedTab = initialTab
        self.logger = logger
    }

    // MARK: - Actions

    /// Selects a tab. If the tab is already selected, increments ``retapCount``
    /// so coordinators can respond (e.g., pop to root).
    ///
    /// Coordinators should observe ``retapCount`` changes and call
    /// ``resetRetapCount()`` after handling the re-tap.
    public func select(_ tab: T) {
        if tab == selectedTab {
            retapCount += 1
            logger.debug("Re-tapped tab: \(String(describing: tab)), count: \(self.retapCount)")
        } else {
            previousTab = selectedTab
            selectedTab = tab
            retapCount = 0
            logger.debug("Switched tab: \(String(describing: tab))")
        }
    }

    /// Resets the re-tap counter. Call this after handling a re-tap event.
    public func resetRetapCount() {
        retapCount = 0
    }
}
