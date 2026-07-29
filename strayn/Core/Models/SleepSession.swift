//
//  SleepSession.swift
//  strayn
//
//  Represents a sleep session with duration and quality metrics
//

import Foundation

struct SleepSession: Identifiable, Codable {
    let id: UUID
    let date: Date  // Night ending on this date
    let startDate: Date
    let endDate: Date

    // Duration
    let totalDuration: TimeInterval  // seconds (actual sleep time)
    let inBedDuration: TimeInterval  // Time in bed (including awake)
    let sleepEfficiency: Double  // 0-1 (sleep time / in-bed time)

    // Sleep stages (if available from HealthKit)
    let deepSleepDuration: TimeInterval?
    let remSleepDuration: TimeInterval?
    let coreSleepDuration: TimeInterval?
    let awakeDuration: TimeInterval

    // Sleep quality indicators
    let averageHRV: Double?
    let averageHeartRate: Double?
    let averageRespiratoryRate: Double?
    let restlessnessScore: Double?  // 0-1, derived from movement

    // Sleep debt accounting
    let sleepNeed: TimeInterval  // What user needed (from their profile)
    let sleepDebt: TimeInterval  // Negative if deficit, positive if surplus

    // Metadata
    let source: SleepSource

    enum SleepSource: String, Codable {
        case appleWatch
        case manual
        case inferred
    }

    init(
        id: UUID = UUID(),
        date: Date,
        startDate: Date,
        endDate: Date,
        totalDuration: TimeInterval,
        inBedDuration: TimeInterval,
        sleepEfficiency: Double,
        deepSleepDuration: TimeInterval? = nil,
        remSleepDuration: TimeInterval? = nil,
        coreSleepDuration: TimeInterval? = nil,
        awakeDuration: TimeInterval = 0,
        averageHRV: Double? = nil,
        averageHeartRate: Double? = nil,
        averageRespiratoryRate: Double? = nil,
        restlessnessScore: Double? = nil,
        sleepNeed: TimeInterval = 28800,
        sleepDebt: TimeInterval = 0,
        source: SleepSource = .appleWatch
    ) {
        self.id = id
        self.date = date
        self.startDate = startDate
        self.endDate = endDate
        self.totalDuration = totalDuration
        self.inBedDuration = inBedDuration
        self.sleepEfficiency = sleepEfficiency
        self.deepSleepDuration = deepSleepDuration
        self.remSleepDuration = remSleepDuration
        self.coreSleepDuration = coreSleepDuration
        self.awakeDuration = awakeDuration
        self.averageHRV = averageHRV
        self.averageHeartRate = averageHeartRate
        self.averageRespiratoryRate = averageRespiratoryRate
        self.restlessnessScore = restlessnessScore
        self.sleepNeed = sleepNeed
        self.sleepDebt = sleepDebt
        self.source = source
    }

    /// Sleep duration in hours
    var durationHours: Double {
        return totalDuration / 3600.0
    }

    /// Sleep efficiency as percentage (0-100)
    var efficiencyPercentage: Double {
        return sleepEfficiency * 100.0
    }

    /// Is this sleep session sufficient for recovery?
    var isSufficient: Bool {
        return sleepDebt >= 0  // No deficit
    }

    /// Quality assessment based on efficiency and duration
    var qualityRating: SleepQuality {
        if sleepEfficiency >= 0.85 && durationHours >= 7.5 {
            return .excellent
        } else if sleepEfficiency >= 0.75 && durationHours >= 6.5 {
            return .good
        } else if sleepEfficiency >= 0.65 || durationHours >= 5.5 {
            return .fair
        } else {
            return .poor
        }
    }

    enum SleepQuality: String, Codable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
    }
}
