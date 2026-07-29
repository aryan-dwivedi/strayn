//
//  PaceOfAging.swift
//  strayn
//
//  Represents how fast Strayn Age is changing based on recent behavior
//  vs long-term baseline. Acts as an early warning / encouragement signal.
//

import Foundation

// MARK: - Pace of Aging

struct PaceOfAging: Codable, Equatable {
    /// The pace value (1.0 = aging at expected rate)
    /// < 1.0 = aging slower than time (improving)
    /// > 1.0 = accelerated aging
    let pace: Double
    
    /// Categorized pace zone
    let zone: PaceZone
    
    /// Per-pillar pace breakdowns
    let sleepPace: PillarPace
    let activityPace: PillarPace
    let cardiovascularPace: PillarPace
    let recoveryPace: PillarPace
    
    /// What's driving the current pace
    let primaryDrivers: [PaceDriver]
    
    /// Trend over past few weeks
    let trend: Trend
    let trendDelta: Double  // Change from last calculation
    
    /// Window used for calculation
    let recentWindowDays: Int      // Usually 30
    let baselineWindowMonths: Int  // Usually 6
    let calculationDate: Date
    
    /// Confidence in the calculation
    let confidence: StraynAge.ConfidenceLevel
    
    // MARK: - Nested Types
    
    enum PaceZone: String, Codable, Equatable {
        case optimal = "Optimal"           // < 0.5x - Excellent longevity pace
        case slow = "Slow"                 // 0.5-0.8x - Good, aging slower
        case steady = "Steady"             // 0.8-1.2x - Aging at expected rate
        case elevated = "Elevated"         // 1.2-1.5x - Slightly accelerated
        case accelerated = "Accelerated"   // > 1.5x - Needs attention
        
        static func zone(for pace: Double) -> PaceZone {
            switch pace {
            case ..<0.5: return .optimal
            case 0.5..<0.8: return .slow
            case 0.8..<1.2: return .steady
            case 1.2..<1.5: return .elevated
            default: return .accelerated
            }
        }
        
        var description: String {
            switch self {
            case .optimal: return "Your recent habits are significantly improving your biological age"
            case .slow: return "You're aging slower than time passes"
            case .steady: return "Your biological age is tracking with your chronological age"
            case .elevated: return "Recent patterns suggest slightly accelerated aging"
            case .accelerated: return "Your recent habits may be accelerating aging"
            }
        }
        
        var colorName: String {
            switch self {
            case .optimal: return "healthspanExcellent"
            case .slow: return "healthspanGood"
            case .steady: return "healthspanNeutral"
            case .elevated: return "healthspanWarning"
            case .accelerated: return "healthspanAlert"
            }
        }
        
        var iconName: String {
            switch self {
            case .optimal: return "sparkles"
            case .slow: return "leaf.fill"
            case .steady: return "equal.circle.fill"
            case .elevated: return "exclamationmark.triangle"
            case .accelerated: return "flame.fill"
            }
        }
        
        var recommendation: String {
            switch self {
            case .optimal: return "Keep up the exceptional work! Your habits are maximizing longevity."
            case .slow: return "You're on a great track. Continue these healthy patterns."
            case .steady: return "Consistent habits are maintaining your health. Small improvements can help you age slower."
            case .elevated: return "Consider reviewing recent sleep patterns or activity levels."
            case .accelerated: return "Focus on recovery, sleep consistency, and moderate activity this week."
            }
        }
    }
    
    struct PillarPace: Codable, Equatable {
        let pillar: Pillar
        let pace: Double
        let zone: PaceZone
        let recentAverage: Double?       // Last 30 days
        let baselineAverage: Double?     // 6-month average
        let changeFromBaseline: Double   // Percentage change
        let impact: Impact
        
        enum Pillar: String, Codable {
            case sleep = "Sleep"
            case activity = "Activity"
            case cardiovascular = "Cardiovascular"
            case recovery = "Recovery"
            
            var iconName: String {
                switch self {
                case .sleep: return "moon.fill"
                case .activity: return "figure.run"
                case .cardiovascular: return "heart.fill"
                case .recovery: return "arrow.trianglehead.counterclockwise"
                }
            }
        }
        
        enum Impact: String, Codable {
            case stronglyPositive = "Strongly Positive"
            case positive = "Positive"
            case neutral = "Neutral"
            case negative = "Negative"
            case stronglyNegative = "Strongly Negative"
            
            var colorName: String {
                switch self {
                case .stronglyPositive, .positive: return "healthspanPositive"
                case .neutral: return "healthspanNeutral"
                case .negative, .stronglyNegative: return "healthspanNegative"
                }
            }
        }
    }
    
    struct PaceDriver: Codable, Equatable, Identifiable {
        let id: UUID
        let metric: String
        let pillar: PillarPace.Pillar
        let direction: Direction
        let magnitude: Magnitude
        let explanation: String
        let actionableInsight: String?
        
        enum Direction: String, Codable {
            case slowing = "Slowing aging"
            case accelerating = "Accelerating aging"
            case maintaining = "Maintaining pace"
        }
        
        enum Magnitude: String, Codable {
            case major = "Major"
            case moderate = "Moderate"
            case minor = "Minor"
        }
        
        init(
            id: UUID = UUID(),
            metric: String,
            pillar: PillarPace.Pillar,
            direction: Direction,
            magnitude: Magnitude,
            explanation: String,
            actionableInsight: String?
        ) {
            self.id = id
            self.metric = metric
            self.pillar = pillar
            self.direction = direction
            self.magnitude = magnitude
            self.explanation = explanation
            self.actionableInsight = actionableInsight
        }
    }
    
    enum Trend: String, Codable, Equatable {
        case improving = "Improving"    // Pace decreasing (good)
        case stable = "Stable"
        case worsening = "Worsening"    // Pace increasing (bad)
        
        var iconName: String {
            switch self {
            case .improving: return "arrow.down.circle.fill"
            case .stable: return "equal.circle.fill"
            case .worsening: return "arrow.up.circle.fill"
            }
        }
        
        var colorName: String {
            switch self {
            case .improving: return "healthspanPositive"
            case .stable: return "healthspanNeutral"
            case .worsening: return "healthspanNegative"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Human-readable pace description
    var paceDescription: String {
        let rounded = pace.rounded(toPlaces: 1)
        if pace < 1.0 {
            return "Aging \(Int((1.0 - pace) * 100))% slower"
        } else if pace > 1.0 {
            return "Aging \(Int((pace - 1.0) * 100))% faster"
        } else {
            return "Aging at expected rate"
        }
    }
    
    /// Formatted pace string
    var formattedPace: String {
        String(format: "%.1fx", pace)
    }
    
    /// Drivers sorted by magnitude
    var driversSortedByImpact: [PaceDriver] {
        primaryDrivers.sorted { driver1, driver2 in
            let order: [PaceDriver.Magnitude: Int] = [.major: 0, .moderate: 1, .minor: 2]
            return (order[driver1.magnitude] ?? 3) < (order[driver2.magnitude] ?? 3)
        }
    }
    
    /// Positive drivers (slowing aging)
    var positiveDrivers: [PaceDriver] {
        primaryDrivers.filter { $0.direction == .slowing }
    }
    
    /// Negative drivers (accelerating aging)
    var negativeDrivers: [PaceDriver] {
        primaryDrivers.filter { $0.direction == .accelerating }
    }
    
    /// Pillar with highest impact on accelerating aging
    var mostConcerningPillar: PillarPace? {
        [sleepPace, activityPace, cardiovascularPace, recoveryPace]
            .max { $0.pace < $1.pace }
    }
    
    /// Pillar with best impact on slowing aging
    var bestPerformingPillar: PillarPace? {
        [sleepPace, activityPace, cardiovascularPace, recoveryPace]
            .min { $0.pace < $1.pace }
    }
    
    // MARK: - Initialization
    
    init(
        pace: Double,
        sleepPace: PillarPace,
        activityPace: PillarPace,
        cardiovascularPace: PillarPace,
        recoveryPace: PillarPace,
        primaryDrivers: [PaceDriver],
        trend: Trend,
        trendDelta: Double,
        recentWindowDays: Int = 30,
        baselineWindowMonths: Int = 6,
        calculationDate: Date = Date(),
        confidence: StraynAge.ConfidenceLevel
    ) {
        self.pace = pace
        self.zone = PaceZone.zone(for: pace)
        self.sleepPace = sleepPace
        self.activityPace = activityPace
        self.cardiovascularPace = cardiovascularPace
        self.recoveryPace = recoveryPace
        self.primaryDrivers = primaryDrivers
        self.trend = trend
        self.trendDelta = trendDelta
        self.recentWindowDays = recentWindowDays
        self.baselineWindowMonths = baselineWindowMonths
        self.calculationDate = calculationDate
        self.confidence = confidence
    }
}

// MARK: - Pace of Aging Input Data

/// Data required to calculate Pace of Aging (30-day recent vs 6-month baseline)
struct PaceOfAgingInputData {
    // Recent (30-day) metrics
    let recentSleepDuration: TimeInterval?
    let recentSleepConsistency: Double?
    let recentDeepSleepPercentage: Double?
    
    let recentWeeklyActivityMinutes: Double?
    let recentDailySteps: Double?
    let recentStrengthMinutes: Double?
    
    let recentRestingHR: Double?
    let recentVO2Max: Double?
    
    let recentHRV: Double?
    let recentRecoveryScore: Double?
    
    // Baseline (6-month) metrics
    let baselineSleepDuration: TimeInterval?
    let baselineSleepConsistency: Double?
    let baselineDeepSleepPercentage: Double?
    
    let baselineWeeklyActivityMinutes: Double?
    let baselineDailySteps: Double?
    let baselineStrengthMinutes: Double?
    
    let baselineRestingHR: Double?
    let baselineVO2Max: Double?
    
    let baselineHRV: Double?
    let baselineRecoveryScore: Double?
    
    // Previous pace for trend
    let previousPace: Double?
    
    // Data quality
    let recentDaysWithData: Int
    let baselineDaysWithData: Int
}
