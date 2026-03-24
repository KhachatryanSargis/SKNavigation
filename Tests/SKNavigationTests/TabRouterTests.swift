import Testing
@testable import SKNavigation

@Suite("TabRouter")
@MainActor
struct TabRouterTests {

    // MARK: - Initial State

    @Test("Initial state has selected tab and no previous")
    func initialState() {
        let router = TabRouter(initialTab: TestTab.first)

        #expect(router.selectedTab == .first)
        #expect(router.previousTab == nil)
        #expect(router.retapCount == 0)
        #expect(router.isTabBarHidden == false)
    }

    // MARK: - Tab Selection

    @Test("Selecting a different tab updates selectedTab")
    func selectDifferentTab() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.second)

        #expect(router.selectedTab == .second)
    }

    @Test("Selecting a different tab sets previousTab")
    func selectDifferentTabSetsPreviousTab() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.second)

        #expect(router.previousTab == .first)
    }

    @Test("Selecting multiple tabs tracks previous correctly")
    func selectMultipleTabsTracksPrevious() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.second)
        router.select(.third)

        #expect(router.selectedTab == .third)
        #expect(router.previousTab == .second)
    }

    @Test("Selecting a different tab resets retap count")
    func selectDifferentTabResetsRetapCount() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.first) // retap
        router.select(.first) // retap again
        #expect(router.retapCount == 2)

        router.select(.second) // switch tab
        #expect(router.retapCount == 0)
    }

    // MARK: - Re-tap Detection

    @Test("Selecting same tab increments retap count")
    func selectSameTabIncrementsRetapCount() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.first)
        #expect(router.retapCount == 1)
    }

    @Test("Selecting same tab multiple times accumulates")
    func selectSameTabMultipleTimesAccumulates() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.first)
        router.select(.first)
        router.select(.first)
        #expect(router.retapCount == 3)
    }

    @Test("Retap does not change previousTab")
    func retapDoesNotChangePreviousTab() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.second)
        let previousBefore = router.previousTab

        router.select(.second) // retap
        #expect(router.previousTab == previousBefore)
    }

    @Test("Retap does not change selectedTab")
    func retapDoesNotChangeSelectedTab() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.second)
        router.select(.second) // retap
        #expect(router.selectedTab == .second)
    }

    // MARK: - Reset Retap Count

    @Test("Reset retap count sets to zero")
    func resetRetapCountSetsToZero() {
        let router = TabRouter(initialTab: TestTab.first)
        router.select(.first)
        router.select(.first)
        #expect(router.retapCount == 2)

        router.resetRetapCount()
        #expect(router.retapCount == 0)
    }

    @Test("Reset retap count on zero is a no-op")
    func resetRetapCountOnZeroIsNoOp() {
        let router = TabRouter(initialTab: TestTab.first)
        router.resetRetapCount()
        #expect(router.retapCount == 0)
    }

    // MARK: - Tab Protocol Defaults

    @Test("Tab id returns self")
    func tabIdReturnsSelf() {
        #expect(TestTab.first.id == .first)
        #expect(TestTab.second.id == .second)
    }

    @Test("Tab accessibilityLabel defaults to title")
    func tabAccessibilityLabelDefaultsToTitle() {
        #expect(TestTab.first.accessibilityLabel == TestTab.first.title)
    }

    @Test("Tab title and icon")
    func tabTitleAndIcon() {
        #expect(TestTab.first.title == "First")
        #expect(TestTab.second.title == "Second")
        #expect(TestTab.third.title == "Third")
        #expect(TestTab.first.icon == "1.circle")
        #expect(TestTab.second.icon == "2.circle")
        #expect(TestTab.third.icon == "3.circle")
    }

    @Test("Tab badge defaults to nil")
    func tabBadgeDefaultsToNil() {
        #expect(TestTab.first.badge == nil)
    }

    @Test("Tab badge can be overridden")
    func tabBadgeCanBeOverridden() {
        #expect(BadgedTab.inbox.badge == "5")
        #expect(BadgedTab.notifications.badge == nil)
    }

    // MARK: - Tab Bar Hidden State

    @Test("isTabBarHidden defaults to false")
    func isTabBarHiddenDefaultsFalse() {
        let router = TabRouter(initialTab: TestTab.first)
        #expect(router.isTabBarHidden == false)
    }

    @Test("isTabBarHidden can be set")
    func isTabBarHiddenCanBeSet() {
        let router = TabRouter(initialTab: TestTab.first)
        router.isTabBarHidden = true
        #expect(router.isTabBarHidden == true)
    }
}
