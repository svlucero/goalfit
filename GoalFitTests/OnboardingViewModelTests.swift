import XCTest
@testable import GoalFit

@MainActor
final class OnboardingViewModelTests: XCTestCase {

    private func makeVM() -> OnboardingViewModel {
        OnboardingViewModel(
            healthService: MockHealthService(),
            notifications: MockNotificationService()
        )
    }

    func testStartsOnWelcome() {
        let vm = makeVM()
        XCTAssertEqual(vm.step, .welcome)
        XCTAssertFalse(vm.isLastStep)
    }

    func testAdvanceWalksAllSteps() {
        let vm = makeVM()
        vm.advance(); XCTAssertEqual(vm.step, .health)
        vm.advance(); XCTAssertEqual(vm.step, .notifications)
        vm.advance(); XCTAssertEqual(vm.step, .firstGoal)
        XCTAssertTrue(vm.isLastStep)
        vm.advance(); XCTAssertEqual(vm.step, .firstGoal, "Should clamp at last step")
    }

    func testGoBack() {
        let vm = makeVM()
        vm.advance(); vm.advance()
        XCTAssertEqual(vm.step, .notifications)
        vm.goBack()
        XCTAssertEqual(vm.step, .health)
        vm.goBack(); vm.goBack()
        XCTAssertEqual(vm.step, .welcome, "Should clamp at first step")
    }

    func testRequestHealthAdvancesAndOnlyAsksOnce() async {
        let vm = makeVM()
        vm.advance() // move to .health
        await vm.requestHealthAndAdvance()
        XCTAssertTrue(vm.didRequestHealth)
        XCTAssertEqual(vm.step, .notifications)

        // Second call (e.g. duplicate tap) should not re-prompt.
        vm.goBack()
        await vm.requestHealthAndAdvance()
        XCTAssertTrue(vm.didRequestHealth)
    }

    func testRequestNotificationsAdvancesAndOnlyAsksOnce() async {
        let vm = makeVM()
        vm.advance(); vm.advance() // move to .notifications
        await vm.requestNotificationsAndAdvance()
        XCTAssertTrue(vm.didRequestNotifications)
        XCTAssertEqual(vm.step, .firstGoal)
    }
}
