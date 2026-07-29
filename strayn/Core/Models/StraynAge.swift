//
//  StraynAge.swift
//  strayn
//
//  Represents a long-term physiological age estimate relative to chronological age.
//  Answers: "Does this body behave younger, older, or in line with my actual age?"
//

import Foundation

// MARK: - Strayn Age

struct StraynAge: Codable, Equatable {
    /// The calculated biological age
    let age: Double
    
    /// User's chronological age at calculation time
    let chronologicalAge: Double
    
    /// Difference from chronological age (negative = younger)
    let ageDelta: Double
    
    /// Component age breakdowns
    let cardiovascularAge: AgeComponent
    let autonomicAge: AgeComponent       // Recovery / Autonomic system
    let sleepAge: AgeComponent
    let metabolicAge: AgeComponent?      // Only if VO2 Max available
    
    /// Confidence in the calculation
    let confidence: ConfidenceLevel
    
    /// Weights used for each component
    let componentWeights: ComponentWeights
    
    /// Trend compared to previous calculation
    let weeklyTrend: Trend?
    let monthlyTrend: Trend?
    
    /// Date range used for calculation
    let calculationWindowStart: Date
    let calculationWindowEnd: Date
    
    // MARK: - Nested Types
    
    struct AgeComponent: Codable, Equatable {
        let name: String
        let estimatedAge: Double
        let ageDelta: Double           // Difference from chronological
        let weight: Double             // 0-1, contribution to final score
        let confidence: ConfidenceLevel
        let primaryDrivers: [Driver]   // What's affecting this component
        
        struct Driver: Codable, Equatable {
            let metric: String
            let impact: Impact
            let value: Double?
            let optimalRange: String?
            let explanation: String
            
            enum Impact: String, Codable {
                case veryPositive = "Very Positive"
                case positive = "Positive"
                case neutral = "Neutral"
                case negative = "Negative"
                case veryNegative = "Very Negative"
                
                var yearsImpact: String {
                    switch self {
                    case .veryPositive: return "−2+ years"
                    case .positive: return "−1 year"
                    case .neutral: return "No impact"
                    case .negative: return "+1 year"
                    case .veryNegative: return "+2+ years"
                    }
                }
                
                var colorName: String {
                    switch self {
                    case .veryPositive, .positive: return "healthspanPositive"
                    case .neutral: return "healthspanNeutral"
                    case .negative, .veryNegative: return "healthspanNegative"
                    }
                }
            }
        }
    }
    
    struct ComponentWeights: Codable, Equatable {
        let cardiovascular: Double
        let autonomic: Double
        let sleep: Double
        let metabolic: Double
        
        static let `default` = ComponentWeights(
            cardiovascular: 0.30,
            autonomic: 0.25,
            sleep: 0.25,
            metabolic: 0.20
        )
        
        static let withoutMetabolic = ComponentWeights(
            cardiovascular: 0.35,
            autonomic: 0.35,
            sleep: 0.30,
            metabolic: 0.0
        )
    }
    
    enum ConfidenceLevel: String, Codable, Equatable {
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        
        var description: String {
            switch self {
            case .high: return "Based on comprehensive data"
            case .medium: return "Based on available data"
            case .low: return "Limited data available"
            }
        }
        
        var iconName: String {
            switch self {
            case .high: return "checkmark.shield.fill"
            case .medium: return "checkmark.shield"
            case .low: return "exclamationmark.shield"
            }
        }
    }
    
    enum Trend: String, Codable, Equatable {
        case improving = "Improving"
        case stable = "Stable"
        case declining = "Declining"
        
        var iconName: String {
            switch self {
            case .improving: return "arrow.down.right"
            case .stable: return "arrow.right"
            case .declining: return "arrow.up.right"
            }
        }
        
        var colorName: String {
            switch self {
            case .improving: return "healthspanPositive"
            case .stable: return "healthspanNeutral"
            case .declining: return "healthspanNegative"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Human-readable age delta description
    var ageDeltaDescription: String {
        let rounded = abs(ageDelta).rounded(toPlaces: 1)
        if ageDelta < -0.5 {
            return "\(rounded) years younger"
        } else if ageDelta > 0.5 {
            return "\(rounded) years older"
        } else {
            return "At your age"
        }
    }
    
    /// Color category based on age delta
    var ageDeltaCategory: AgeDeltaCategory {
        if ageDelta <= -2.0 {
            return .excellent
        } else if ageDelta <= -0.5 {
            return .good
        } else if ageDelta <= 0.5 {
            return .onTrack
        } else if ageDelta <= 2.0 {
            return .attention
        } else {
            return .concern
        }
    }
    
    enum AgeDeltaCategory: String, Codable {
        case excellent = "Excellent"
        case good = "Good"
        case onTrack = "On Track"
        case attention = "Needs Attention"
        case concern = "Concern"
        
        var colorName: String {
            switch self {
            case .excellent: return "healthspanExcellent"
            case .good: return "healthspanGood"
            case .onTrack: return "healthspanNeutral"
            case .attention: return "healthspanWarning"
            case .concern: return "healthspanAlert"
            }
        }
        
        var description: String {
            switch self {
            case .excellent: return "Your biological systems are performing exceptionally well"
            case .good: return "Your body is aging slower than average"
            case .onTrack: return "Your biological age matches your chronological age"
            case .attention: return "Some areas could use improvement"
            case .concern: return "Your lifestyle may be accelerating aging"
            }
        }
    }
    
    /// All components sorted by impact (most concerning first)
    var componentsSortedByImpact: [AgeComponent] {
        var components = [cardiovascularAge, autonomicAge, sleepAge]
        if let metabolic = metabolicAge {
            components.append(metabolic)
        }
        return components.sorted { $0.ageDelta > $1.ageDelta }
    }
    
    /// Top positive drivers across all components
    var topPositiveDrivers: [AgeComponent.Driver] {
        componentsSortedByImpact
            .flatMap { $0.primaryDrivers }
            .filter { $0.impact == .positive || $0.impact == .veryPositive }
            .prefix(3)
            .map { $0 }
    }
    
    /// Top negative drivers across all components
    var topNegativeDrivers: [AgeComponent.Driver] {
        componentsSortedByImpact
            .flatMap { $0.primaryDrivers }
            .filter { $0.impact == .negative || $0.impact == .veryNegative }
            .prefix(3)
            .map { $0 }
    }
    
    // MARK: - Initialization
    
    init(
        age: Double,
        chronologicalAge: Double,
        cardiovascularAge: AgeComponent,
        autonomicAge: AgeComponent,
        sleepAge: AgeComponent,
        metabolicAge: AgeComponent?,
        confidence: ConfidenceLevel,
        componentWeights: ComponentWeights,
        weeklyTrend: Trend?,
        monthlyTrend: Trend?,
        calculationWindowStart: Date,
        calculationWindowEnd: Date
    ) {
        self.age = age
        self.chronologicalAge = chronologicalAge
        self.ageDelta = age - chronologicalAge
        self.cardiovascularAge = cardiovascularAge
        self.autonomicAge = autonomicAge
        self.sleepAge = sleepAge
        self.metabolicAge = metabolicAge
        self.confidence = confidence
        self.componentWeights = componentWeights
        self.weeklyTrend = weeklyTrend
        self.monthlyTrend = monthlyTrend
        self.calculationWindowStart = calculationWindowStart
        self.calculationWindowEnd = calculationWindowEnd
    }
}

// MARK: - Helper Extension

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - Strayn Age Input Data

/// Aggregated data required to calculate Strayn Age
struct StraynAgeInputData {
    // Sleep Pillar
    let averageSleepDuration: TimeInterval?          // 6-month avg
    let sleepConsistencyScore: Double?               // 0-100, bed/wake variance
    let deepSleepPercentage: Double?                 // 0-1
    let remSleepPercentage: Double?                  // 0-1
    let sleepEfficiencyAverage: Double?              // 0-1
    
    // Activity & Strain Pillar
    let weeklyModerateAerobicMinutes: Double?        // Zones 1-3
    let weeklyHighIntensityMinutes: Double?          // Zones 4-5
    let weeklyStrengthTrainingMinutes: Double?       // Weights, yoga, etc.
    let dailyStepAverage: Double?
    let stepConsistencyScore: Double?                // 0-100
    
    // Cardiovascular Fitness Pillar
    let restingHeartRateAverage: Double?             // 6-month avg
    let restingHeartRateTrend: Baseline.TrendDirection?
    let vo2Max: Double?                              // From HealthKit
    let vo2MaxTrend: Baseline.TrendDirection?
    let cardiacEfficiencyScore: Double?              // Derived metric
    
    // Recovery Pillar
    let hrvAverage: Double?                          // 6-month SDNN avg
    let hrvTrend: Baseline.TrendDirection?
    let averageRecoveryScore: Double?                // 0-100
    let recoveryConsistency: Double?                 // 0-100
    
    // User Context
    let chronologicalAge: Int
    let biologicalSex: User.BiologicalSex
    let height: Double?                              // cm
    let weight: Double?                              // kg
    let leanBodyMass: Double?                        // kg, if available
    
    // Data Quality
    let daysWithSleepData: Int
    let daysWithActivityData: Int
    let daysWithHeartRateData: Int
    let totalDaysInWindow: Int
}
