import XCTest
@testable import GoalFit

final class ProgressCalculatorTests: XCTestCase {

    // MARK: - atLeast (acumulativos)

    func testAtLeast_partialProgress() {
        let goal = Goal(title: "Pasos", type: .steps, targetValue: 10000)
        XCTAssertEqual(ProgressCalculator.fraction(for: goal, currentValue: 5000), 0.5, accuracy: 0.0001)
        XCTAssertFalse(ProgressCalculator.isCompleted(for: goal, currentValue: 5000))
    }

    func testAtLeast_completedAndClampedAtOne() {
        let goal = Goal(title: "Pasos", type: .steps, targetValue: 10000)
        XCTAssertEqual(ProgressCalculator.fraction(for: goal, currentValue: 12000), 1.0, accuracy: 0.0001)
        XCTAssertTrue(ProgressCalculator.isCompleted(for: goal, currentValue: 12000))
    }

    func testAtLeast_exactlyMetIsCompleted() {
        let goal = Goal(title: "Ejercicio", type: .exerciseMinutes, targetValue: 30)
        XCTAssertTrue(ProgressCalculator.isCompleted(for: goal, currentValue: 30))
        XCTAssertEqual(ProgressCalculator.fraction(for: goal, currentValue: 30), 1.0, accuracy: 0.0001)
    }

    func testAtLeast_zeroTargetIsSafe() {
        let goal = Goal(title: "Edge", type: .steps, targetValue: 0)
        XCTAssertEqual(ProgressCalculator.fraction(for: goal, currentValue: 100), 0)
    }

    // MARK: - atMost

    func testAtMost_belowLimitIsComplete() {
        let goal = Goal(title: "Límite", type: .activeEnergy, direction: .atMost, targetValue: 500)
        XCTAssertTrue(ProgressCalculator.isCompleted(for: goal, currentValue: 400))
        XCTAssertEqual(ProgressCalculator.fraction(for: goal, currentValue: 400), 1.0, accuracy: 0.0001)
    }

    func testAtMost_aboveLimitNotComplete() {
        let goal = Goal(title: "Límite", type: .activeEnergy, direction: .atMost, targetValue: 500)
        XCTAssertFalse(ProgressCalculator.isCompleted(for: goal, currentValue: 1000))
        XCTAssertEqual(ProgressCalculator.fraction(for: goal, currentValue: 1000), 0.5, accuracy: 0.0001)
    }

    // MARK: - reach (peso)

    func testReach_weightLoss_partial() {
        // De 80 kg hacia 70 kg; actual 75 → mitad del camino.
        let goal = Goal(title: "Peso", type: .bodyMass, targetValue: 70, startValue: 80)
        XCTAssertEqual(ProgressCalculator.fraction(for: goal, currentValue: 75), 0.5, accuracy: 0.0001)
        XCTAssertFalse(ProgressCalculator.isCompleted(for: goal, currentValue: 75))
    }

    func testReach_weightLoss_completedWithinTolerance() {
        let goal = Goal(title: "Peso", type: .bodyMass, targetValue: 70, startValue: 80)
        XCTAssertTrue(ProgressCalculator.isCompleted(for: goal, currentValue: 70.05))
        XCTAssertTrue(ProgressCalculator.isCompleted(for: goal, currentValue: 69.5))
    }

    func testReach_weightGain_partial() {
        // De 60 kg hacia 65 kg; actual 62.5 → mitad.
        let goal = Goal(title: "Peso", type: .bodyMass, targetValue: 65, startValue: 60)
        XCTAssertEqual(ProgressCalculator.fraction(for: goal, currentValue: 62.5), 0.5, accuracy: 0.0001)
        XCTAssertTrue(ProgressCalculator.isCompleted(for: goal, currentValue: 65))
    }

    func testReach_noStartValue_completesOnlyAtTarget() {
        let goal = Goal(title: "Peso", type: .bodyMass, targetValue: 70, startValue: nil)
        XCTAssertTrue(ProgressCalculator.isCompleted(for: goal, currentValue: 70.05))
        XCTAssertFalse(ProgressCalculator.isCompleted(for: goal, currentValue: 72))
    }

    // MARK: - progress() agregada

    func testProgressBundlesValues() {
        let goal = Goal(title: "Pasos", type: .steps, targetValue: 10000)
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 86400)
        let now = Date(timeIntervalSince1970: 1000)

        let result = ProgressCalculator.progress(
            for: goal, currentValue: 7500,
            periodStart: start, periodEnd: end, now: now
        )

        XCTAssertEqual(result.goalId, goal.id)
        XCTAssertEqual(result.currentValue, 7500)
        XCTAssertEqual(result.targetValue, 10000)
        XCTAssertEqual(result.fraction, 0.75, accuracy: 0.0001)
        XCTAssertEqual(result.percent, 75)
        XCTAssertFalse(result.isCompleted)
        XCTAssertEqual(result.periodStart, start)
        XCTAssertEqual(result.periodEnd, end)
        XCTAssertEqual(result.lastUpdated, now)
    }
}
