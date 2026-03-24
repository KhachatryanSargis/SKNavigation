# SKNavigation

[![Swift](https://img.shields.io/badge/Swift-6.1+-orange?logo=swift)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17%2B-blue?logo=apple)](https://developer.apple.com/ios/)
[![macOS](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple)](https://developer.apple.com/macos/)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen?logo=swift)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)

A lightweight, type-safe SwiftUI navigation library built on the Coordinator pattern. Drive push navigation, modal sheets, tab bars, and complex flows from observable coordinators — no boilerplate, no singletons, no `AnyView`.

---

## Requirements

- iOS 17+ / macOS 14+
- Swift 6.1+
- Xcode 16.3+

---

## Installation

**Xcode:** File > Add Package Dependencies > enter the repository URL, select *Up to Next Major Version* from `1.0.0`.

**`Package.swift`:**

```swift
dependencies: [
    .package(url: "<repository-url>", from: "1.0.0")
],
targets: [
    .target(name: "YourTarget", dependencies: ["SKNavigation"])
]
```

---

## Quick Start

### 1 — Define Routes

```swift
enum CatalogRoute: Route {
    case list
    case detail(id: String)
    case filter(category: String)
    case settings

    // Hide the tab bar on detail screens
    var hidesTabBar: Bool {
        switch self {
        case .detail, .filter: return true
        default: return false
        }
    }
}
```

### 2 — Create a Coordinator

```swift
@Observable
@MainActor
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
        case .list:
            CatalogListView(coordinator: self)
        case .detail(let id):
            CatalogDetailView(id: id, coordinator: self)
        case .filter(let category):
            FilterView(category: category, coordinator: self)
        case .settings:
            SettingsView(coordinator: self)
        }
    }

    func showDetail(id: String)          { router.push(.detail(id: id)) }
    func showFilter(category: String)    { router.push(.filter(category: category)) }
    func showSettings()                  { router.present(.settings, as: .sheet(.bottomSheet)) }
    func goBack()                        { router.pop() }
}
```

### 3 — Wire Into Your App

```swift
@main
struct MyApp: App {
    @State private var coordinator = CatalogCoordinator()

    var body: some Scene {
        WindowGroup {
            CoordinatedView(coordinator: coordinator)
        }
    }
}
```

`CoordinatedView` automatically binds the router's stack to `NavigationStack`, and modal state to `.sheet` and `.fullScreenCover`.

---

## Core API

### NavigationRouter

The single source of truth for a coordinator's navigation state.

```swift
// Stack operations
router.push(.detail(id: "abc"))
router.pop()                         // pop one
router.pop(count: 3)                 // pop multiple
router.popTo(.list)                  // pop to a specific route
router.popToRoot()
router.setStack([.list, .detail(id: "abc")])

// Modal presentation
router.present(.settings, as: .sheet())
router.present(.settings, as: .sheet(.bottomSheet))
router.present(.detail(id: "1"), as: .fullScreenCover)
router.dismiss()

// State queries
router.isAtRoot       // true if stack is empty
router.stackDepth     // number of routes in the stack
router.isPresenting   // true if a modal is active
router.topRoute       // the topmost route, or nil
router.shouldHideTabBar // true if topRoute.hidesTabBar is true

// Full reset
router.reset()

// Navigation action callback (for analytics/logging)
router.onNavigationAction = { action in
    print("Navigation: \(action)")
}
```

### Presentation Styles

```swift
// Large sheet (default)
router.present(.settings, as: .sheet())

// Bottom sheet with medium + large detents
router.present(.settings, as: .sheet(.bottomSheet))

// Full-screen cover (iOS only)
router.present(.settings, as: .fullScreenCover)

// Custom sheet configuration
router.present(.settings, as: .sheet(SheetConfiguration(
    detents: [.medium],
    dragIndicatorVisibility: .visible,
    isDismissDisabled: true,
    cornerRadius: 24
)))

// Reusable presets
extension SheetConfiguration {
    static let compact = SheetConfiguration(detents: [.medium], cornerRadius: 20)
    static let nonDismissible = SheetConfiguration(isDismissDisabled: true)
}
router.present(.checkout, as: .sheet(.compact))
```

---

## Tab Navigation

### Define Tabs

```swift
enum AppTab: String, Tab {
    case home, search, favorites, profile

    var title: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .home:      "house"
        case .search:    "magnifyingglass"
        case .favorites: "heart.fill"
        case .profile:   "person.circle"
        }
    }

    // Optional badge
    var badge: String? {
        switch self {
        case .favorites: "3"
        default: nil
        }
    }
}
```

### Tab Coordinator

```swift
@Observable
@MainActor
final class AppCoordinator: TabCoordinator {
    typealias TabType = AppTab

    let tabRouter = TabRouter(initialTab: AppTab.home)

    private(set) lazy var homeCoordinator = HomeCoordinator()
    private(set) lazy var searchCoordinator = SearchCoordinator()
    private(set) lazy var favoritesCoordinator = FavoritesCoordinator()
    private(set) lazy var profileCoordinator = ProfileCoordinator()

    @ViewBuilder
    func coordinatorView(for tab: AppTab) -> some View {
        switch tab {
        case .home:      CoordinatedView(coordinator: homeCoordinator)
        case .search:    CoordinatedView(coordinator: searchCoordinator)
        case .favorites: CoordinatedView(coordinator: favoritesCoordinator)
        case .profile:   CoordinatedView(coordinator: profileCoordinator)
        }
    }
}

// In your app:
TabCoordinatedView(coordinator: appCoordinator)
```

### Route-Based Tab Bar Hiding

The tab bar visibility is driven by the `hidesTabBar` property on the `Route` protocol. When the active tab's top route has `hidesTabBar == true`, the tab bar hides automatically.

```swift
enum HomeRoute: Route {
    case feed
    case articleDetail(id: String)
    case playerFullScreen(videoId: String)

    var hidesTabBar: Bool {
        switch self {
        case .articleDetail, .playerFullScreen: return true
        default: return false
        }
    }
}
```

The coordinator must update the tab router's hidden state when the navigation stack changes:

```swift
@Observable
@MainActor
final class HomeCoordinator: Coordinator {
    typealias RouteType = HomeRoute

    let router = NavigationRouter<HomeRoute>()
    weak var tabRouter: TabRouter<AppTab>?

    init() {
        router.onNavigationAction = { [weak self] _ in
            self?.tabRouter?.isTabBarHidden = self?.router.shouldHideTabBar ?? false
        }
    }

    // ... rootView(), destination(for:)
}
```

Wire the tab router in the parent:

```swift
// In AppCoordinator
homeCoordinator.tabRouter = tabRouter
```

---

## Flow Coordinators

For linear flows (checkout, onboarding, authentication) that return a typed result to their parent:

```swift
// Define the flow's output
enum OnboardingOutput: Sendable {
    case completed(userId: String)
    case skipped
}

// Define the flow's routes
enum OnboardingRoute: Route {
    case welcome
    case permissions
    case profileSetup
    case completion
}

// Implement the flow coordinator
@Observable
@MainActor
final class OnboardingCoordinator: FlowCoordinator {
    typealias RouteType = OnboardingRoute
    typealias Output = OnboardingOutput

    let router = NavigationRouter<OnboardingRoute>()
    let resultHandler = CoordinatorResultHandler<OnboardingOutput>()

    func start() async -> CoordinatorResult<OnboardingOutput> {
        await resultHandler.awaitResult()
    }

    func showPermissions()    { router.push(.permissions) }
    func showProfileSetup()   { router.push(.profileSetup) }
    func showCompletion()     { router.push(.completion) }

    func didComplete(userId: String) {
        resultHandler.finish(with: .completed(userId: userId))
    }

    func didSkip() {
        resultHandler.finish(with: .skipped)
    }

    func didCancel() {
        resultHandler.cancel()
    }
}

// Parent coordinator starts and awaits the result:
func startOnboarding() {
    Task {
        let flow = OnboardingCoordinator()
        self.onboardingCoordinator = flow
        router.present(.onboarding, as: .fullScreenCover)

        let result = await flow.start()
        router.dismiss()
        self.onboardingCoordinator = nil

        switch result {
        case .finished(.completed(let userId)):
            print("Onboarding completed for \(userId)")
        case .finished(.skipped):
            print("User skipped onboarding")
        case .cancelled:
            break
        }
    }
}
```

---

## Authenticated / Unauthenticated Transitions

Model your app's auth state as an explicit three-phase state machine. This eliminates the "auth flash" bug where unauthenticated UI flickers before the session is validated.

```swift
// Auth state
enum AuthState {
    case launch                          // validating session
    case unauthenticated                 // show login/register
    case authenticated(session: Session) // show main app
}

// Root coordinator manages the state machine
@Observable
@MainActor
final class RootCoordinator {
    private(set) var authState: AuthState = .launch

    private var launchCoordinator: LaunchCoordinator?
    private var authCoordinator: AuthCoordinator?
    private var appCoordinator: AppCoordinator?

    private let sessionService: SessionServiceProtocol

    init(sessionService: SessionServiceProtocol) {
        self.sessionService = sessionService
        startLaunch()
    }

    private func startLaunch() {
        let coordinator = LaunchCoordinator(sessionService: sessionService)
        self.launchCoordinator = coordinator

        Task {
            let result = await coordinator.start()

            switch result {
            case .finished(.authenticated(let session)):
                transition(to: .authenticated(session: session))
            case .finished(.needsAuth):
                transition(to: .unauthenticated)
            case .cancelled:
                transition(to: .unauthenticated)
            }
        }
    }

    func transition(to state: AuthState) {
        // Release the outgoing coordinator tree
        launchCoordinator = nil
        authCoordinator = nil
        appCoordinator = nil

        authState = state

        switch state {
        case .launch:
            startLaunch()
        case .unauthenticated:
            authCoordinator = AuthCoordinator()
        case .authenticated(let session):
            appCoordinator = AppCoordinator(session: session)
        }
    }

    func signOut() {
        transition(to: .unauthenticated)
    }
}

// Root view switches on auth state
struct RootView: View {
    let coordinator: RootCoordinator

    var body: some View {
        Group {
            switch coordinator.authState {
            case .launch:
                LaunchView()
            case .unauthenticated:
                if let auth = coordinator.authCoordinator {
                    CoordinatedView(coordinator: auth)
                }
            case .authenticated:
                if let app = coordinator.appCoordinator {
                    TabCoordinatedView(coordinator: app)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.authState)
    }
}
```

Only one branch of the coordinator tree exists in memory at any time. Transitioning between states releases the outgoing coordinator tree entirely.

---

## Complex Nested Flows

Coordinators can compose arbitrarily. A tab coordinator can contain feature coordinators, which can spawn flow coordinators, which can present sub-flows:

```swift
@Observable
@MainActor
final class CartCoordinator: Coordinator {
    typealias RouteType = CartRoute

    let router = NavigationRouter<CartRoute>()
    private var checkoutCoordinator: CheckoutCoordinator?

    // ... rootView(), destination(for:)

    func startCheckout() {
        let checkout = CheckoutCoordinator(cart: currentCart)
        self.checkoutCoordinator = checkout

        Task {
            router.present(.checkout, as: .fullScreenCover)
            let result = await checkout.start()
            router.dismiss()
            self.checkoutCoordinator = nil

            switch result {
            case .finished(.success(let orderId)):
                router.push(.orderConfirmation(id: orderId))
            case .finished(.needsPaymentUpdate):
                router.present(.paymentSettings, as: .sheet())
            case .cancelled:
                break
            }
        }
    }
}

// CheckoutCoordinator can itself spawn a sub-flow:
@Observable
@MainActor
final class CheckoutCoordinator: FlowCoordinator {
    typealias RouteType = CheckoutRoute
    typealias Output = CheckoutOutput

    let router = NavigationRouter<CheckoutRoute>()
    let resultHandler = CoordinatorResultHandler<CheckoutOutput>()
    private var addressCoordinator: AddressFlowCoordinator?

    func start() async -> CoordinatorResult<CheckoutOutput> {
        await resultHandler.awaitResult()
    }

    func addNewAddress() {
        let addressFlow = AddressFlowCoordinator()
        self.addressCoordinator = addressFlow

        Task {
            router.present(.addressFlow, as: .sheet())
            let result = await addressFlow.start()
            router.dismiss()
            self.addressCoordinator = nil

            if case .finished(let address) = result {
                updateShippingAddress(address)
            }
        }
    }

    func confirmOrder(orderId: String) {
        resultHandler.finish(with: .success(orderId: orderId))
    }

    func didCancel() {
        resultHandler.cancel()
    }
}
```

---

## Cross-Module Navigation

Features navigate to destinations in other features without importing them. Each feature coordinator exposes a closure the app layer sets:

```swift
// Define your app's module identifiers
enum AppModule: String, Hashable, Sendable {
    case home, search, favorites, profile, settings
}

// In SearchCoordinator — no knowledge of ProfileCoordinator
@Observable
@MainActor
final class SearchCoordinator: Coordinator {
    typealias RouteType = SearchRoute

    let router = NavigationRouter<SearchRoute>()
    var onCrossModuleNavigation: ((CrossModuleDestination<AppModule>) -> Void)?

    func showUserProfile(userId: String) {
        onCrossModuleNavigation?(CrossModuleDestination(
            targetModule: .profile,
            identifier: userId,
            parameters: ["userId": userId],
            preferredStrategy: .switchTabAndPush
        ))
    }

    func previewItem(itemId: String) {
        onCrossModuleNavigation?(CrossModuleDestination(
            targetModule: .home,
            identifier: itemId,
            parameters: ["itemId": itemId],
            preferredStrategy: .presentSheet
        ))
    }

    // ... rootView(), destination(for:)
}

// AppCoordinator resolves it
extension AppCoordinator: CrossModuleNavigationHandler {
    func navigate(to destination: CrossModuleDestination<AppModule>) {
        switch destination.targetModule {
        case .profile:
            tabRouter.select(.profile)
            let userId = destination.parameters["userId"] ?? ""
            profileCoordinator.router.push(.detail(userId: userId))

        case .home:
            let itemId = destination.parameters["itemId"] ?? ""
            switch destination.preferredStrategy {
            case .switchTabAndPush:
                tabRouter.select(.home)
                homeCoordinator.router.push(.detail(id: itemId))
            case .presentSheet:
                homeCoordinator.router.present(.detail(id: itemId), as: .sheet())
            case .presentFullScreenCover:
                homeCoordinator.router.present(.detail(id: itemId), as: .fullScreenCover)
            }

        case .search, .favorites, .settings:
            break
        }
    }
}

// Wire during initialization
searchCoordinator.onCrossModuleNavigation = { [weak self] destination in
    self?.navigate(to: destination)
}
```

---

## Deep Linking

Conform your app coordinator to `DeepLinkable` and handle incoming URLs:

```swift
extension AppCoordinator: DeepLinkable {
    func handle(url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return false }

        switch host {
        case "product":
            guard let id = components.queryItems?.first(where: { $0.name == "id" })?.value else {
                return false
            }
            tabRouter.select(.home)
            homeCoordinator.router.popToRoot()
            homeCoordinator.router.push(.detail(id: id))
            return true

        case "profile":
            guard let userId = components.queryItems?.first(where: { $0.name == "userId" })?.value else {
                return false
            }
            tabRouter.select(.profile)
            profileCoordinator.router.popToRoot()
            profileCoordinator.router.push(.detail(userId: userId))
            return true

        default:
            return false
        }
    }
}

// In your App struct:
@main
struct MyApp: App {
    @State private var rootCoordinator = RootCoordinator(sessionService: ProductionSessionService())

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: rootCoordinator)
                .onOpenURL { url in
                    _ = rootCoordinator.appCoordinator?.handle(url: url)
                }
        }
    }
}
```

---

## Testing

All navigation logic is unit-testable without a simulator. Tests use Swift Testing (`@Test`, `@Suite`).

### Testing Coordinator Navigation

```swift
@Suite("CatalogCoordinator")
@MainActor
struct CatalogCoordinatorTests {

    @Test("showDetail pushes detail route")
    func showDetailPushesRoute() {
        let coordinator = CatalogCoordinator()
        coordinator.showDetail(id: "item-42")

        #expect(coordinator.router.path == [.detail(id: "item-42")])
        #expect(coordinator.router.stackDepth == 1)
    }

    @Test("showSettings presents as bottom sheet")
    func showSettingsPresentsSheet() {
        let coordinator = CatalogCoordinator()
        coordinator.showSettings()

        #expect(coordinator.router.sheet == .settings)
        #expect(coordinator.router.currentSheetConfiguration == .bottomSheet)
    }

    @Test("goBack pops from stack")
    func goBackPops() {
        let coordinator = CatalogCoordinator()
        coordinator.showDetail(id: "1")
        coordinator.showFilter(category: "electronics")
        coordinator.goBack()

        #expect(coordinator.router.path == [.detail(id: "1")])
    }
}
```

### Testing Flow Coordinators

```swift
@Suite("OnboardingFlow")
@MainActor
struct OnboardingFlowTests {

    @Test("Completing onboarding returns userId")
    func completionReturnsUserId() async {
        let coordinator = OnboardingCoordinator()

        let result = await coordinator.resultHandler.awaitResult {
            coordinator.didComplete(userId: "user-123")
        }

        #expect(result.output == .completed(userId: "user-123"))
    }

    @Test("Cancelling onboarding returns cancelled")
    func cancellationReturnsCancelled() async {
        let coordinator = OnboardingCoordinator()

        let result = await coordinator.resultHandler.awaitResult {
            coordinator.didCancel()
        }

        #expect(result.isCancelled)
    }

    @Test("Skipping onboarding returns skipped")
    func skipReturnsSkipped() async {
        let coordinator = OnboardingCoordinator()

        let result = await coordinator.resultHandler.awaitResult {
            coordinator.didSkip()
        }

        #expect(result.output == .skipped)
    }
}
```

### Testing Tab Navigation

```swift
@Suite("AppCoordinator Tabs")
@MainActor
struct AppCoordinatorTabTests {

    @Test("Initial tab is home")
    func initialTab() {
        let coordinator = AppCoordinator(session: mockSession)
        #expect(coordinator.tabRouter.selectedTab == .home)
    }

    @Test("Switching to profile tab")
    func switchToProfile() {
        let coordinator = AppCoordinator(session: mockSession)
        coordinator.tabRouter.select(.profile)

        #expect(coordinator.tabRouter.selectedTab == .profile)
        #expect(coordinator.tabRouter.previousTab == .home)
    }

    @Test("Re-tapping same tab triggers retap")
    func retapDetection() {
        let coordinator = AppCoordinator(session: mockSession)
        coordinator.tabRouter.select(.home) // retap

        #expect(coordinator.tabRouter.retapCount == 1)
    }
}
```

### Testing Auth State Transitions

```swift
@Suite("RootCoordinator Auth")
@MainActor
struct RootCoordinatorAuthTests {

    @Test("Sign out releases app coordinator")
    func signOutReleasesAppCoordinator() {
        let root = RootCoordinator(sessionService: MockSessionService())
        root.transition(to: .authenticated(session: mockSession))
        weak var weakApp = root.appCoordinator

        root.signOut()

        #expect(weakApp == nil)
        #expect(root.authCoordinator != nil)
    }

    @Test("Transition to authenticated creates app coordinator")
    func authenticatedCreatesAppCoordinator() {
        let root = RootCoordinator(sessionService: MockSessionService())
        root.transition(to: .authenticated(session: mockSession))

        #expect(root.appCoordinator != nil)
        #expect(root.authCoordinator == nil)
    }
}
```

### Testing Cross-Module Navigation

```swift
@Suite("Cross-Module Navigation")
@MainActor
struct CrossModuleTests {

    @Test("Search to profile switches tab and pushes")
    func searchToProfile() {
        let coordinator = AppCoordinator(session: mockSession)

        coordinator.navigate(to: CrossModuleDestination(
            targetModule: .profile,
            identifier: "user-1",
            parameters: ["userId": "user-1"],
            preferredStrategy: .switchTabAndPush
        ))

        #expect(coordinator.tabRouter.selectedTab == .profile)
        #expect(coordinator.profileCoordinator.router.path.count == 1)
    }
}
```

---

## Package Structure

```
SKNavigation/
├── Package.swift
├── README.md
├── Sources/SKNavigation/
│   ├── Route/
│   │   ├── Route.swift              # Route protocol with hidesTabBar
│   │   └── PresentationStyle.swift  # Sheet, fullScreenCover, push
│   ├── Router/
│   │   ├── NavigationAction.swift   # Declarative navigation mutations
│   │   ├── NavigationRouter.swift   # Observable navigation state
│   │   └── TabRouter.swift          # Tab protocol and tab state
│   ├── Coordinator/
│   │   ├── Coordinator.swift        # Coordinator and FlowCoordinator protocols
│   │   ├── CoordinatorResult.swift  # Typed flow outcomes
│   │   ├── CoordinatorResultHandler.swift  # Async result bridging
│   │   └── TabCoordinator.swift     # Tab coordinator protocol
│   ├── View/
│   │   ├── CoordinatedView.swift    # NavigationStack wiring
│   │   └── TabCoordinatedView.swift # TabView wiring with tab bar hiding
│   ├── CrossModule/
│   │   └── CrossModuleNavigation.swift  # Cross-module navigation types
│   ├── DeepLink/
│   │   └── DeepLinkable.swift       # Deep link handling protocols
│   └── Transition/
│       └── TransitionConfiguration.swift  # Custom transition animations
└── Tests/SKNavigationTests/
    ├── Helpers/TestHelpers.swift
    ├── RouteTests.swift
    ├── PresentationStyleTests.swift
    ├── NavigationRouterTests.swift
    ├── TabRouterTests.swift
    ├── CoordinatorResultTests.swift
    ├── CoordinatorResultHandlerTests.swift
    └── CrossModuleNavigationTests.swift
```

---

## License

MIT
