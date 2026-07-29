//
//  DailyRecovery.swift
//  strayn
//
//  Represents a daily recovery score and its component metrics
//

import Foundation

struct DailyRecovery: Identifiable, Codable {
    let id: UUID
    let date: Date  // Calendar date (00:00 of the day)

    // Overall score
    let recoveryScore: Double  // 0-100
    let recoveryZone: RecoveryZone  // .green, .yellow, .red

    // Component scores (normalized vs baseline, 0-100)
    let hrvScore: Double
    let restingHRScore: Double
    let sleepScore: Double
    let respiratoryRateScore: Double

    // Raw values for transparency
    let rawHRV: Double?  // ms (SDNN)
    let rawRestingHR: Double?  // bpm
    let rawSleepDuration: TimeInterval?  // seconds
    let rawRespiratoryRate: Double?  // breaths/min

    // Baselines used for calculation
    let hrvBaseline: Double?
    let restingHRBaseline: Double?

    // Advanced Physiological Metrics (Biological OS)
    let autonomicBalance: Double?     // 0-1.0 (Parasympathetic vs Sympathetic)
    let stressLoad: Double?           // 0-100 (Composite index)
    let cardiacEfficiency: Double?    // Strain / Avg HR ratio
    let recoveryContributors: [String: Double]? // e.g. ["hrv": 12.0, "sleepDebt": -18.0]
    let straynAge: Double?            // Biological age according to Strayn algorithms
    let rawVO2Max: Double?            // mL/kg/min

    // Metadata
    let calculatedAt: Date
    let hasInsufficientData: Bool
    let dataQualityScore: Double  // 0-1, based on data completeness
    let journalData: String?      // JSON string of morning journal answers

    enum RecoveryZone: String, Codable {
        case green
        case yellow
        case red

        /// Get the zone for a given recovery score
        static func zone(for score: Double) -> RecoveryZone {
            if score >= 67 {
                return .green
            } else if score >= 34 {
                return .yellow
            } else {
                return .red
            }
        }

        /// Human-readable description
        var description: String {
            switch self {
            case .green:
                return "Ready"
            case .yellow:
                return "Moderate"
            case .red:
                return "Low"
            }
        }

        /// Recommended strain range for this recovery zone
        var recommendedStrainRange: ClosedRange<Double> {
            switch self {
            case .green:
                return 10.0...21.0  // High strain allowed
            case .yellow:
                return 5.0...12.0   // Moderate strain
            case .red:
                return 0.0...8.0    // Light activity only
            }
        }
    }

    init(
        id: UUID = UUID(),
        date: Date,
        recoveryScore: Double,
        recoveryZone: RecoveryZone,
        hrvScore: Double,
        restingHRScore: Double,
        sleepScore: Double,
        respiratoryRateScore: Double,
        rawHRV: Double? = nil,
        rawRestingHR: Double? = nil,
        rawSleepDuration: TimeInterval? = nil,
        rawRespiratoryRate: Double? = nil,
        hrvBaseline: Double? = nil,
        restingHRBaseline: Double? = nil,
        autonomicBalance: Double? = nil,
        stressLoad: Double? = nil,
        cardiacEfficiency: Double? = nil,
        recoveryContributors: [String: Double]? = nil,
        straynAge: Double? = nil,
        rawVO2Max: Double? = nil,
        calculatedAt: Date = Date(),
        hasInsufficientData: Bool = false,
        dataQualityScore: Double = 1.0,
        journalData: String? = nil
    ) {
        self.id = id
        self.date = date
        self.recoveryScore = recoveryScore
        self.recoveryZone = recoveryZone
        self.hrvScore = hrvScore
        self.restingHRScore = restingHRScore
        self.sleepScore = sleepScore
        self.respiratoryRateScore = respiratoryRateScore
        self.rawHRV = rawHRV
        self.rawRestingHR = rawRestingHR
        self.rawSleepDuration = rawSleepDuration
        self.rawRespiratoryRate = rawRespiratoryRate
        self.hrvBaseline = hrvBaseline
        self.restingHRBaseline = restingHRBaseline
        self.autonomicBalance = autonomicBalance
        self.stressLoad = stressLoad
        self.cardiacEfficiency = cardiacEfficiency
        self.recoveryContributors = recoveryContributors
        self.straynAge = straynAge
        self.rawVO2Max = rawVO2Max
        self.calculatedAt = calculatedAt
        self.hasInsufficientData = hasInsufficientData
        self.dataQualityScore = dataQualityScore
        self.journalData = journalData
    }
}
