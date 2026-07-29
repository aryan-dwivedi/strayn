//
//  DailyStrain.swift
//  strayn
//
//  Represents daily cardiovascular strain from all activity
//

import Foundation

struct DailyStrain: Identifiable, Codable {
    let id: UUID
    let date: Date  // Calendar date

    // Overall strain
    let strainScore: Double  // 0-21

    // Time in zones (seconds)
    let timeInZone1: TimeInterval  // <60% max HR
    let timeInZone2: TimeInterval  // 60-70%
    let timeInZone3: TimeInterval  // 70-80%
    let timeInZone4: TimeInterval  // 80-90%
    let timeInZone5: TimeInterval  // 90-100%

    // Activity breakdown
    let workoutStrain: Double  // Strain from logged workouts
    let dailyActivityStrain: Double  // Strain from non-workout activity

    // Associated workouts (UUIDs of HKWorkout samples)
    let workoutIds: [String]

    // Metadata
    let lastUpdated: Date
    let isComplete: Bool  // False if day is still ongoing

    init(
        id: UUID = UUID(),
        date: Date,
        strainScore: Double,
        timeInZone1: TimeInterval = 0,
        timeInZone2: TimeInterval = 0,
        timeInZone3: TimeInterval = 0,
        timeInZone4: TimeInterval = 0,
        timeInZone5: TimeInterval = 0,
        workoutStrain: Double = 0,
        dailyActivityStrain: Double = 0,
        workoutIds: [String] = [],
        lastUpdated: Date = Date(),
        isComplete: Bool = false
    ) {
        self.id = id
        self.date = date
        self.strainScore = strainScore
        self.timeInZone1 = timeInZone1
        self.timeInZone2 = timeInZone2
        self.timeInZone3 = timeInZone3
        self.timeInZone4 = timeInZone4
        self.timeInZone5 = timeInZone5
        self.workoutStrain = workoutStrain
        self.dailyActivityStrain = dailyActivityStrain
        self.workoutIds = workoutIds
        self.lastUpdated = lastUpdated
        self.isComplete = isComplete
    }

    /// Total time spent with elevated heart rate (any zone)
    var totalActiveTime: TimeInterval {
        return timeInZone1 + timeInZone2 + timeInZone3 + timeInZone4 + timeInZone5
    }

    /// Get time spent in a specific zone
    func time(in zone: Int) -> TimeInterval {
        switch zone {
        case 1: return timeInZone1
        case 2: return timeInZone2
        case 3: return timeInZone3
        case 4: return timeInZone4
        case 5: return timeInZone5
        default: return 0
        }
    }

    /// Strain intensity category
    var intensityCategory: StrainIntensity {
        if strainScore < 5 {
            return .light
        } else if strainScore < 10 {
            return .moderate
        } else if strainScore < 15 {
            return .hard
        } else {
            return .veryHard
        }
    }

    enum StrainIntensity: String, Codable {
        case light = "Light Day"
        case moderate = "Moderate Day"
        case hard = "Hard Day"
        case veryHard = "Very Hard Day"
    }
}
