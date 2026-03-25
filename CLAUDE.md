# SKNavigation — Package Rules

Claude reads this file when working on files inside the SKNavigation package.
This file is owned by SKNavigation and committed alongside the code.

## Package Overview

SKNavigation is a lightweight, type-safe SwiftUI navigation library built on the
Coordinator pattern. It depends on SKCore. iOS 17+ / macOS 14+, Swift 6.1,
strict concurrency.

## Key Types

| Area | Types | Notes |
|---|---|---|
| **Coordinator** | `Coordinator`, `TabCoordinator`, `CoordinatorResult`, `CoordinatorResultHandler` | `@Observable @MainActor`, drives all navigation |
| **Router** | `NavigationRouter<R>`, `TabRouter`, `NavigationAction` | Owns navigation state, used by coordinators |
| **Route** | `Route` protocol, `PresentationStyle` | Define routes as enums conforming to `Route` |
| **Views** | `CoordinatedView`, `TabCoordinatedView` | SwiftUI views that wire up coordinators |
| **CrossModule** | `CrossModuleNavigation` | Navigate between feature modules |
| **DeepLink** | `DeepLinkable` | Deep link handling protocol |

## Conventions Specific to This Package

### Defining Routes
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

### Creating Coordinators
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

### Navigation Actions
Use the router for all navigation — never use SwiftUI's `NavigationLink` directly:
```swift
// Push
coordinator.router.push(.detail(id: "123"))

// Present modally
coordinator.router.present(.settings, style: .sheet)

// Pop / dismiss
coordinator.router.pop()
coordinator.router.dismiss()
```

### Tab Coordination
Use `TabCoordinator` + `TabCoordinatedView` for tab-based navigation:
```swift
@Observable @MainActor
final class AppTabCoordinator: TabCoordinator {
    // Each tab has its own child coordinator
}
```

### Cross-Module Navigation
Use `CrossModuleNavigation` to navigate between feature boundaries without direct dependencies.

### Testing in SKNavigation
- Test coordinators by verifying router state after navigation actions
- Mock coordinators via the `Coordinator` protocol
- Test deep link resolution via `DeepLinkable`

### Build & Test
```bash
cd SKNavigation
swift build
swift test
```

## Design Rules
- Coordinators own routers, views don't
- Views receive coordinators as dependencies, never create them
- All navigation state lives in the router — views are stateless with respect to navigation
- Tab bar visibility is determined by the `Route`, not the view
- No `AnyView` — use `@ViewBuilder` in coordinator's `destination(for:)`
