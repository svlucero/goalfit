import XCTest
@testable import GoalFit

@MainActor
final class HealthKitProgressProviderTests: XCTestCase {

    func testProgressUsesHealthValue() async {
        let goal = Goal(title: "Steps", type: .steps, targetValue: 10000)
        let health = MockHealthService(valueProvider: { _ in 7500 })
        let provider = HealthKitProgressProvider(health: health)

        let progress = await provider.progress(for: goal)

        XCTAssertEqual(progress.currentValue, 7500)
        XCTAssertEqual(progress.fraction, 0.75, accuracy: 0.0001)
        XCTAssertFalse(progress.isCompleted)
    }

    func testProgressMarksCompleted() async {
        let goal = Goal(title: "Exercise", type: .exerciseMinutes, targetValue: 30)
        let health = MockHealthService(valueProvider: { _ in 35 })
        let provider = HealthKitProgressProvider(health: health)

        let progress = await provider.progress(for: goal)

        XCTAssertTrue(progress.isCompleted)
        XCTAssertEqual(progress.fraction, 1.0, accuracy: 0.0001)
    }

    func testWeightReachProgress() async {
        let goal = Goal(title: "Weight", type: .bodyMass, targetValue: 70, startValue: 80)
        let health = MockHealthService(valueProvider: { _ in 75 }) // halfway
        let provider = HealthKitProgressProvider(health: health)

        let progress = await provider.progress(for: goal)

        XCTAssertEqual(progress.currentValue, 75)
        XCTAssertEqual(progress.fraction, 0.5, accuracy: 0.0001)
    }
}
