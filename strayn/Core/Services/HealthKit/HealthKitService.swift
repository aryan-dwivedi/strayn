//
//  HealthKitService.swift
//  strayn
//
//  Service for HealthKit data access and permissions
//

import Foundation
import HealthKit

class HealthKitService {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()

    // MARK: - Type Identifiers

    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
    private let respiratoryRateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
    private let sleepAnalysisType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    private let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max)!
    private let workoutType = HKObjectType.workoutType()

    // MARK: - Availability

    /// Check if HealthKit is available on this device
    var isAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Permissions

    /// Request essential HealthKit permissions (MVP features)
    func requestEssentialAuthorization() async throws {
        let typesToRead: Set<HKSampleType> = [
            heartRateType,
            hrvType,
            restingHRType,
            sleepAnalysisType,
            workoutType,
            vo2MaxType
        ]

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }

    /// Request advanced permissions (V1 features)
    func requestAdvancedAuthorization() async throws {
        let typesToRead: Set<HKSampleType> = [
            respiratoryRateType,
            activeEnergyType
        ]

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }

    /// Request menstrual cycle permissions (V2 features)
    func requestMenstrualCycleAuthorization() async throws {
        guard let menstrualFlowType = HKCategoryType.categoryType(forIdentifier: .menstrualFlow) else {
            return
        }

        let typesToRead: Set<HKSampleType> = [menstrualFlowType]
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }

    /// Check if we have authorization for a specific type
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return healthStore.authorizationStatus(for: type)
    }

    // MARK: - HRV Queries

    /// Fetch HRV samples for a specific date (typically overnight)
    func fetchHRVSamples(for date: Date) async throws -> [Double] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let hrvValues = (samples as? [HKQuantitySample])?.compactMap {
                    $0.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                } ?? []

                continuation.resume(returning: hrvValues)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch average overnight HRV (primary recovery metric)
    func fetchOvernightHRV(for date: Date) async throws -> Double? {
        // HRV typically measured during sleep (22:00 previous day to 06:00 target day)
        let targetMorning = Calendar.current.startOfDay(for: date)
        let previousEvening = Calendar.current.date(byAdding: .hour, value: -8, to: targetMorning)!

        let predicate = HKQuery.predicateForSamples(
            withStart: previousEvening,
            end: targetMorning,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let hrvSamples = samples as? [HKQuantitySample] ?? []
                guard !hrvSamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Calculate mean HRV
                let total = hrvSamples.reduce(0.0) {
                    $0 + $1.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                }
                let mean = total / Double(hrvSamples.count)

                continuation.resume(returning: mean)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Resting Heart Rate

    /// Fetch resting heart rate for a specific date
    func fetchRestingHeartRate(for date: Date) async throws -> Double? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: restingHRType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let rhr = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: rhr)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Respiratory Rate

    /// Fetch respiratory rate for a specific date (overnight)
    func fetchRespiratoryRate(for date: Date) async throws -> Double? {
        let targetMorning = Calendar.current.startOfDay(for: date)
        let previousEvening = Calendar.current.date(byAdding: .hour, value: -8, to: targetMorning)!

        let predicate = HKQuery.predicateForSamples(
            withStart: previousEvening,
            end: targetMorning,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: respiratoryRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let rrSamples = samples as? [HKQuantitySample] ?? []
                guard !rrSamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Calculate mean respiratory rate
                let total = rrSamples.reduce(0.0) {
                    $0 + $1.quantity.doubleValue(for: HKUnit(from: "count/min"))
                }
                let mean = total / Double(rrSamples.count)

                continuation.resume(returning: mean)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Sleep Analysis

    /// Fetch sleep samples for a specific night (ending on target date)
    func fetchSleepAnalysis(for date: Date) async throws -> [HKCategorySample] {
        // Sleep for "date" means the night ending on that date
        // Look from 12 hours before to the start of day
        let targetMorning = Calendar.current.startOfDay(for: date)
        let previousEvening = Calendar.current.date(byAdding: .hour, value: -12, to: targetMorning)!

        let predicate = HKQuery.predicateForSamples(
            withStart: previousEvening,
            end: targetMorning,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepAnalysisType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let sleepSamples = (samples as? [HKCategorySample]) ?? []
                continuation.resume(returning: sleepSamples)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - VO2 Max

    /// Fetch latest VO2 Max sample
    func fetchVO2Max(for date: Date) async throws -> Double? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // VO2 Max is usually infrequent, look back 7 days if none today
        let lookbackStart = Calendar.current.date(byAdding: .day, value: -7, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(
            withStart: lookbackStart,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: vo2MaxType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let vo2 = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit(from: "ml/kg*min"))
                continuation.resume(returning: vo2)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Heart Rate

    /// Fetch all heart rate samples for a specific date (for strain calculation)
    func fetchHeartRateSamples(for date: Date) async throws -> [HKQuantitySample] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let hrSamples = (samples as? [HKQuantitySample]) ?? []
                continuation.resume(returning: hrSamples)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Workouts

    /// Fetch workouts for a specific date
    func fetchWorkouts(for date: Date) async throws -> [HKWorkout] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Background Delivery

    /// Enable background delivery for a specific type
    func enableBackgroundDelivery(for types: Set<HKSampleType>, frequency: HKUpdateFrequency = .immediate) async throws {
        for type in types {
            try await healthStore.enableBackgroundDelivery(for: type, frequency: frequency)
        }
    }

    /// Disable background delivery
    func disableBackgroundDelivery(for types: Set<HKSampleType>) async throws {
        for type in types {
            try await healthStore.disableBackgroundDelivery(for: type)
        }
    }
}

// MARK: - HealthKit Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case permissionDenied
    case noData

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .permissionDenied:
            return "HealthKit permission was denied. Please enable in Settings."
        case .noData:
            return "No HealthKit data available for the requested period"
        }
    }
}
