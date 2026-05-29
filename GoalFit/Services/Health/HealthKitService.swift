import Foundation
import HealthKit

/// Maps domain goal types to HealthKit types and units.
extension GoalType {
    var quantityTypeIdentifier: HKQuantityTypeIdentifier {
        switch self {
        case .steps: return .stepCount
        case .distance: return .distanceWalkingRunning
        case .activeEnergy: return .activeEnergyBurned
        case .exerciseMinutes: return .appleExerciseTime
        case .bodyMass: return .bodyMass
        }
    }

    var quantityType: HKQuantityType {
        HKQuantityType(quantityTypeIdentifier)
    }

    var healthKitUnit: HKUnit {
        switch self {
        case .steps: return .count()
        case .distance: return .meterUnit(with: .kilo)
        case .activeEnergy: return .kilocalorie()
        case .exerciseMinutes: return .minute()
        case .bodyMass: return .gramUnit(with: .kilo)
        }
    }
}

/// Real HealthKit-backed implementation of `HealthDataProviding` (read-only).
final class HealthKitService: HealthDataProviding {
    private let store = HKHealthStore()

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization(for types: [GoalType]) async throws {
        guard isHealthDataAvailable else { return }
        let readTypes = Set(types.map { $0.quantityType as HKObjectType })
        guard !readTypes.isEmpty else { return }
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    func currentValue(for goal: Goal) async throws -> Double {
        guard isHealthDataAvailable else { return 0 }
        let type = goal.type.quantityType
        let unit = goal.type.healthKitUnit

        if goal.type.isCumulative {
            let (start, end) = PeriodResolver.bounds(for: goal)
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let stats = try await statistics(type: type, predicate: predicate, options: .cumulativeSum)
            return stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
        } else {
            // Target metrics (weight): latest sample across a wide window.
            let stats = try await statistics(type: type, predicate: nil, options: .discreteMostRecent)
            return stats?.mostRecentQuantity()?.doubleValue(for: unit) ?? 0
        }
    }

    func dailySeries(for goal: Goal, days: Int) async throws -> [HealthDataPoint] {
        guard isHealthDataAvailable, days > 0 else { return [] }
        let type = goal.type.quantityType
        let unit = goal.type.healthKitUnit
        let calendar = Calendar.current
        let end = Date()
        let anchor = calendar.startOfDay(for: end)
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: anchor) ?? anchor
        let cumulative = goal.type.isCumulative
        let options: HKStatisticsOptions = cumulative ? .cumulativeSum : .discreteAverage

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let collection = try await statisticsCollection(
            type: type,
            predicate: predicate,
            options: options,
            anchorDate: anchor,
            interval: DateComponents(day: 1)
        )

        var points: [HealthDataPoint] = []
        collection?.enumerateStatistics(from: start, to: end) { stats, _ in
            let quantity = cumulative ? stats.sumQuantity() : stats.averageQuantity()
            let value = quantity?.doubleValue(for: unit) ?? 0
            points.append(HealthDataPoint(date: stats.startDate, value: value))
        }
        return points
    }

    // MARK: - Query wrappers (async)

    private func statistics(
        type: HKQuantityType,
        predicate: NSPredicate?,
        options: HKStatisticsOptions
    ) async throws -> HKStatistics? {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: options
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: statistics)
                }
            }
            store.execute(query)
        }
    }

    private func statisticsCollection(
        type: HKQuantityType,
        predicate: NSPredicate?,
        options: HKStatisticsOptions,
        anchorDate: Date,
        interval: DateComponents
    ) async throws -> HKStatisticsCollection? {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: options,
                anchorDate: anchorDate,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, collection, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: collection)
                }
            }
            store.execute(query)
        }
    }
}
