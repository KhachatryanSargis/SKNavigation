import Foundation

// MARK: - Route Protocol

/// A type-safe navigation destination.
///
/// Each feature module defines its own `Route` enum conforming to this protocol.
/// Routes carry all the data needed to construct the destination view.
///
/// Example:
/// ```swift
/// enum SettingsRoute: Route {
///     case general
///     case notifications
///     case privacy(userId: String)
///
///     var hidesTabBar: Bool {
///         switch self {
///         case .privacy: return true
///         default: return false
///         }
///     }
/// }
/// ```
public protocol Route: Hashable, Identifiable, Sendable {

    /// Whether this route should hide the tab bar when displayed.
    ///
    /// Override this in your route enum to hide the tab bar for specific destinations.
    /// Defaults to `false`.
    var hidesTabBar: Bool { get }
}

// MARK: - Default Implementations

extension Route {

    /// Default identity derived from the route's hash value.
    ///
    /// Override this in your concrete route if you need stable identity
    /// across navigation state restorations.
    public var id: Int { hashValue }

    /// Tab bar is visible by default.
    public var hidesTabBar: Bool { false }
}
