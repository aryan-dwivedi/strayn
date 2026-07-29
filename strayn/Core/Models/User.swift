//
//  User.swift
//  strayn
//
//  Core domain model representing a user profile
//

import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    var age: Int
    var biologicalSex: BiologicalSex
    var maxHeartRate: Int?  // Optional, can be calculated or user-provided
    var restingHeartRateTrend: Double?
    var hasMenstrualCycle: Bool
    var sleepNeedHours: Double  // Default 8.0, user can adjust
    var onboardingCompleted: Bool
    var isPremiumUser: Bool  // For freemium feature gating
    var createdAt: Date
    var updatedAt: Date

    enum BiologicalSex: String, Codable {
        case male
        case female
        case other
    }

    init(
        id: UUID = UUID(),
        age: Int,
        biologicalSex: BiologicalSex,
        maxHeartRate: Int? = nil,
        restingHeartRateTrend: Double? = nil,
        hasMenstrualCycle: Bool = false,
        sleepNeedHours: Double = 8.0,
        onboardingCompleted: Bool = false,
        isPremiumUser: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.age = age
        self.biologicalSex = biologicalSex
        self.maxHeartRate = maxHeartRate
        self.restingHeartRateTrend = restingHeartRateTrend
        self.hasMenstrualCycle = hasMenstrualCycle
        self.sleepNeedHours = sleepNeedHours
        self.onboardingCompleted = onboardingCompleted
        self.isPremiumUser = isPremiumUser
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Estimate max heart rate using Fox formula (more accurate than 220-age)
    /// Returns: 208 - (0.7 × age)
    func estimatedMaxHeartRate() -> Int {
        return maxHeartRate ?? (208 - Int(0.7 * Double(age)))
    }
}
