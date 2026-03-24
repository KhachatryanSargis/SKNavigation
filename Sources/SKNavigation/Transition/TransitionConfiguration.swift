import SwiftUI

// MARK: - Transition Configuration

/// Defines custom transition animations for navigation actions.
///
/// The default implementation uses system transitions. Provide a custom
/// conformance to override push, sheet, or full-screen cover animations.
///
/// Example:
/// ```swift
/// struct FadeTransition: TransitionConfiguration {
///     var pushTransition: AnyTransition { .opacity }
///     var sheetAnimation: Animation { .easeInOut(duration: 0.3) }
/// }
/// ```
public protocol TransitionConfiguration: Sendable {

    /// The transition applied when pushing onto the navigation stack.
    var pushTransition: AnyTransition { get }

    /// The animation applied to sheet presentations.
    var sheetAnimation: Animation { get }

    /// The animation applied to full-screen cover presentations.
    var fullScreenCoverAnimation: Animation { get }
}

// MARK: - System Default Transition

/// Uses the platform's default navigation transitions.
public struct SystemTransition: TransitionConfiguration {

    public init() {}

    public var pushTransition: AnyTransition { .slide }
    public var sheetAnimation: Animation { .default }
    public var fullScreenCoverAnimation: Animation { .default }
}
