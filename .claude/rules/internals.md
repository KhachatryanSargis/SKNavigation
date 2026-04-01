---
paths:
  - "Sources/**/*.swift"
  - "Tests/**/*.swift"
  - "Package.swift"
---
# SKNavigation — Internal Conventions

Loaded only when editing SKNavigation source or test files directly.

## Defining Routes

Routes are enums conforming to `Route`. Each case represents a destination:
```swift
enum CatalogRoute: Route {
    case list
    case detail(id: String)
    case settings

    var hidesTabBar: Bool {
        switch self {
        case .detail: return true
        default: return false
        }
    }
}
```

## Creating Coordinators

Coordinators are `@Observable @MainActor` and own a `NavigationRouter`:
```swift
@Observable @MainActor
final class CatalogCoordinator: Coordinator {
    typealias RouteType = CatalogRoute
    let router = NavigationRouter<CatalogRoute>()

    @ViewBuilder
    func rootView() -> some View {
        CatalogListView(coordinator: self)
    }

    @ViewBuilder
    func destination(for route: CatalogRoute) -> some View {
        switch route {
        case .list: CatalogListView(coordinator: self)
        case .detail(let id): CatalogDetailView(id: id, coordinator: self)
        case .settings: SettingsView()
        }
    }
}
```

## Navigation Actions

Use the router for all navigation — never use SwiftUI's `NavigationLink` directly:
```swift
// Push
coordinator.router.push(.detail(id: "123"))

// Present modally (note: parameter label is `as:`)
coordinator.router.present(.settings, as: .sheet())
coordinator.router.present(.settings, as: .sheet(.bottomSheet))
coordinator.router.present(.settings, as: .fullScreenCover)

// Pop / dismiss
coordinator.router.pop()
coordinator.router.dismiss()
```

## Flow Coordinators

Use `FlowCoordinator` for linear flows that return a typed result:
```swift
@Observable @MainActor
final class OnboardingCoordinator: FlowCoordinator {
    typealias RouteType = OnboardingRoute
    typealias Output = OnboardingOutput

    let router = NavigationRouter<OnboardingRoute>()
    let resultHandler = CoordinatorResultHandler<OnboardingOutput>()

    func start() async -> CoordinatorResult<OnboardingOutput> {
        await resultHandler.awaitResult()
    }
}
```

## Tab Coordination

Use `TabCoordinator` + `TabCoordinatedView` for tab-based navigation.
Define tabs as enums conforming to the `Tab` protocol:
```swift
@Observable @MainActor
final class AppTabCoordinator: TabCoordinator {
    typealias TabType = AppTab
    let tabRouter = TabRouter(initialTab: AppTab.home)
    // Each tab has its own child coordinator
}
```

## Cross-Module Navigation

Use `CrossModuleDestination` and `CrossModuleNavigationHandler` to navigate
between feature boundaries without direct dependencies.

## Testing

- Test coordinators by verifying router state after navigation actions
- Test flow coordinators by awaiting `CoordinatorResult` values
- Mock coordinators via the `Coordinator` protocol
- Test deep link resolution via `DeepLinkable`
- Use Swift Testing (`@Suite`, `@Test`, `#expect`) exclusively — no XCTest

## Build & Test

```bash
cd SKNavigation
swift build
swift test
```

## Design Rules

- Coordinators own routers, views don't
- Views receive coordinators as dependencies, never create them
- All navigation state lives in the router — views are stateless with respect to navigation
- Tab bar visibility is determined by the `Route.hidesTabBar` property, not the view
- No `AnyView` — use `@ViewBuilder` in coordinator's `destination(for:)`
- All public API must be documented with `///` comments
- Only one coordinator tree branch should be alive at a time (auth transitions release the outgoing tree)
