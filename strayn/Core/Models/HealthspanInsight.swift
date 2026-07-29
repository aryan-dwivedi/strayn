//
//  HealthspanInsight.swift
//  strayn
//
//  Natural language insights for Healthspan feature explaining
//  correlations, trends, and actionable recommendations.
//

import Foundation

// MARK: - Healthspan Insight

struct HealthspanInsight: Identifiable, Codable {
    let id: UUID
    let date: Date
    
    // Content
    let title: String
    let message: String
    let category: InsightCategory
    let priority: Priority
    
    // Confidence & Attribution
    let confidence: ConfidenceLevel
    let attribution: Attribution
    
    // Related Data
    let relatedPillar: PaceOfAging.PillarPace.Pillar?
    let relatedMetrics: [String: Double]
    let impactOnStraynAge: ImpactLevel?
    let impactOnPace: ImpactLevel?
    
    // Actionability
    let recommendation: String?
    let timeframe: Timeframe?
    let difficulty: ActionDifficulty?
    
    // Metadata
    let createdAt: Date
    var isRead: Bool
    var isDismissed: Bool
    
    // MARK: - Nested Types
    
    enum InsightCategory: String, Codable {
        case straynAge = "Strayn Age"
        case paceOfAging = "Pace of Aging"
        case sleep = "Sleep"
        case activity = "Activity"
        case cardiovascular = "Cardiovascular"
        case recovery = "Recovery"
        case milestone = "Milestone"
        case warning = "Warning"
        case encouragement = "Encouragement"
        
        var iconName: String {
            switch self {
            case .straynAge: return "sparkles"
            case .paceOfAging: return "gauge.with.needle.fill"
            case .sleep: return "moon.fill"
            case .activity: return "figure.run"
            case .cardiovascular: return "heart.fill"
            case .recovery: return "arrow.trianglehead.counterclockwise"
            case .milestone: return "trophy.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .encouragement: return "hand.thumbsup.fill"
            }
        }
        
        var colorName: String {
            switch self {
            case .straynAge: return "healthspanPrimary"
            case .paceOfAging: return "healthspanSecondary"
            case .sleep: return "healthspanSleep"
            case .activity: return "healthspanActivity"
            case .cardiovascular: return "healthspanCardio"
            case .recovery: return "healthspanRecovery"
            case .milestone: return "healthspanMilestone"
            case .warning: return "healthspanWarning"
            case .encouragement: return "healthspanPositive"
            }
        }
    }
    
    enum Priority: Int, Codable, Comparable {
        case critical = 1
        case high = 2
        case medium = 3
        case low = 4
        case informational = 5
        
        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    enum ConfidenceLevel: String, Codable {
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        
        var description: String {
            switch self {
            case .high: return "Strong correlation in your data"
            case .medium: return "Moderate correlation observed"
            case .low: return "Based on limited data"
            }
        }
        
        var iconName: String {
            switch self {
            case .high: return "checkmark.circle.fill"
            case .medium: return "circle.lefthalf.filled"
            case .low: return "questionmark.circle"
            }
        }
    }
    
    enum Attribution: Codable {
        case population          // Based on population research
        case personal            // Based on user's own data patterns
        case combined            // Both personal and population data
        
        var disclaimer: String {
            switch self {
            case .population:
                return "Based on population-level health research. Individual results may vary."
            case .personal:
                return "Based on patterns in your personal health data."
            case .combined:
                return "Combines your data with population health research."
            }
        }
    }
    
    enum ImpactLevel: String, Codable {
        case major = "Major Impact"
        case moderate = "Moderate Impact"
        case minor = "Minor Impact"
        case neutral = "Neutral"
    }
    
    enum Timeframe: String, Codable {
        case immediate = "Start Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case longTerm = "Long-term Goal"
    }
    
    enum ActionDifficulty: String, Codable {
        case easy = "Easy"
        case moderate = "Moderate"
        case challenging = "Challenging"
        
        var iconName: String {
            switch self {
            case .easy: return "1.circle.fill"
            case .moderate: return "2.circle.fill"
            case .challenging: return "3.circle.fill"
            }
        }
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        title: String,
        message: String,
        category: InsightCategory,
        priority: Priority,
        confidence: ConfidenceLevel,
        attribution: Attribution = .combined,
        relatedPillar: PaceOfAging.PillarPace.Pillar? = nil,
        relatedMetrics: [String: Double] = [:],
        impactOnStraynAge: ImpactLevel? = nil,
        impactOnPace: ImpactLevel? = nil,
        recommendation: String? = nil,
        timeframe: Timeframe? = nil,
        difficulty: ActionDifficulty? = nil,
        createdAt: Date = Date(),
        isRead: Bool = false,
        isDismissed: Bool = false
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.message = message
        self.category = category
        self.priority = priority
        self.confidence = confidence
        self.attribution = attribution
        self.relatedPillar = relatedPillar
        self.relatedMetrics = relatedMetrics
        self.impactOnStraynAge = impactOnStraynAge
        self.impactOnPace = impactOnPace
        self.recommendation = recommendation
        self.timeframe = timeframe
        self.difficulty = difficulty
        self.createdAt = createdAt
        self.isRead = isRead
        self.isDismissed = isDismissed
    }
    
    // MARK: - Computed Properties
    
    var isCritical: Bool {
        priority == .critical
    }
    
    var isActionable: Bool {
        recommendation != nil
    }
}

// MARK: - Insight Templates

extension HealthspanInsight {
    
    // MARK: - Sleep Insights
    
    static func sleepConsistencyImproving(
        consistencyScore: Double,
        paceImpact: Double
    ) -> HealthspanInsight {
        HealthspanInsight(
            title: "Sleep Consistency Improving",
            message: "Your recent sleep consistency (\(Int(consistencyScore))%) is helping slow your Pace of Aging. Consistent bed/wake times support circadian rhythm health.",
            category: .sleep,
            priority: .medium,
            confidence: .high,
            attribution: .combined,
            relatedPillar: .sleep,
            relatedMetrics: ["sleepConsistency": consistencyScore, "paceImpact": paceImpact],
            impactOnPace: .moderate,
            recommendation: "Maintain your current sleep schedule, even on weekends.",
            timeframe: .thisWeek,
            difficulty: .moderate
        )
    }
    
    static func sleepDurationLow(
        averageDuration: Double,
        targetDuration: Double
    ) -> HealthspanInsight {
        let hoursShort = (targetDuration - averageDuration) / 3600
        return HealthspanInsight(
            title: "Sleep Duration Below Optimal",
            message: "You're averaging \(String(format: "%.1f", averageDuration / 3600)) hours of sleep, about \(String(format: "%.1f", hoursShort)) hours short of optimal. This may be increasing your Pace of Aging.",
            category: .sleep,
            priority: .high,
            confidence: .high,
            attribution: .combined,
            relatedPillar: .sleep,
            relatedMetrics: ["averageSleep": averageDuration, "target": targetDuration],
            impactOnStraynAge: .moderate,
            impactOnPace: .major,
            recommendation: "Try moving your bedtime 15-30 minutes earlier this week.",
            timeframe: .thisWeek,
            difficulty: .easy
        )
    }
    
    // MARK: - Activity Insights
    
    static func aerobicActivityExcellent(
        weeklyMinutes: Double
    ) -> HealthspanInsight {
        HealthspanInsight(
            title: "Excellent Aerobic Activity",
            message: "You logged \(Int(weeklyMinutes)) minutes of moderate aerobic activity this week. This level of activity is associated with improved cardiovascular age.",
            category: .activity,
            priority: .low,
            confidence: .high,
            attribution: .population,
            relatedPillar: .activity,
            relatedMetrics: ["weeklyAerobicMinutes": weeklyMinutes],
            impactOnStraynAge: .moderate,
            recommendation: "Keep up this level of activity for long-term benefits.",
            timeframe: .longTerm,
            difficulty: .moderate
        )
    }
    
    static func strengthTrainingLow(
        weeklyMinutes: Double
    ) -> HealthspanInsight {
        HealthspanInsight(
            title: "Strength Training Opportunity",
            message: "You logged \(Int(weeklyMinutes)) minutes of strength training. Research suggests 2-4 sessions per week supports healthy aging and lean mass preservation.",
            category: .activity,
            priority: .medium,
            confidence: .medium,
            attribution: .population,
            relatedPillar: .activity,
            relatedMetrics: ["weeklyStrengthMinutes": weeklyMinutes],
            impactOnStraynAge: .minor,
            recommendation: "Consider adding 1-2 strength sessions per week.",
            timeframe: .thisMonth,
            difficulty: .moderate
        )
    }
    
    // MARK: - Cardiovascular Insights
    
    static func restingHRImproving(
        current: Double,
        baseline: Double
    ) -> HealthspanInsight {
        let improvement = baseline - current
        return HealthspanInsight(
            title: "Resting Heart Rate Improving",
            message: "Your resting HR has dropped \(String(format: "%.0f", improvement)) bpm from your baseline. Lower resting HR is associated with better cardiovascular health.",
            category: .cardiovascular,
            priority: .medium,
            confidence: .high,
            attribution: .personal,
            relatedPillar: .cardiovascular,
            relatedMetrics: ["currentRHR": current, "baselineRHR": baseline],
            impactOnStraynAge: .moderate,
            recommendation: "Continue your current training and recovery patterns.",
            timeframe: .longTerm,
            difficulty: .moderate
        )
    }
    
    static func vo2MaxDecline(
        current: Double,
        previous: Double
    ) -> HealthspanInsight {
        let decline = previous - current
        return HealthspanInsight(
            title: "VO₂ Max Trending Down",
            message: "Your estimated VO₂ Max has decreased by \(String(format: "%.1f", decline)) mL/kg/min. This metric reflects cardiovascular fitness and is correlated with longevity.",
            category: .cardiovascular,
            priority: .high,
            confidence: .medium,
            attribution: .combined,
            relatedPillar: .cardiovascular,
            relatedMetrics: ["currentVO2": current, "previousVO2": previous],
            impactOnStraynAge: .major,
            impactOnPace: .major,
            recommendation: "Add 2-3 sessions of Zone 2 cardio (60-70% max HR) weekly.",
            timeframe: .thisMonth,
            difficulty: .moderate
        )
    }
    
    // MARK: - Recovery Insights
    
    static func hrvTrendingUp(
        current: Double,
        baseline: Double
    ) -> HealthspanInsight {
        let improvement = current - baseline
        return HealthspanInsight(
            title: "HRV Trending Upward",
            message: "Your HRV has increased by \(String(format: "%.0f", improvement)) ms from your baseline. Higher HRV indicates better autonomic health and recovery capacity.",
            category: .recovery,
            priority: .medium,
            confidence: .high,
            attribution: .personal,
            relatedPillar: .recovery,
            relatedMetrics: ["currentHRV": current, "baselineHRV": baseline],
            impactOnStraynAge: .moderate
        )
    }
    
    // MARK: - Milestone Insights
    
    static func straynAgeImproved(
        previousAge: Double,
        currentAge: Double
    ) -> HealthspanInsight {
        let improvement = previousAge - currentAge
        return HealthspanInsight(
            title: "Strayn Age Improved",
            message: "Your Strayn Age decreased by \(String(format: "%.1f", improvement)) years this week! Your consistent healthy behaviors are paying off.",
            category: .milestone,
            priority: .low,
            confidence: .high,
            attribution: .personal,
            relatedMetrics: ["previousAge": previousAge, "currentAge": currentAge],
            impactOnStraynAge: .major
        )
    }
    
    static func paceOptimalAchieved() -> HealthspanInsight {
        HealthspanInsight(
            title: "Optimal Pace Achieved!",
            message: "Your Pace of Aging is in the optimal zone. Your recent habits are significantly supporting longevity. Keep it up!",
            category: .milestone,
            priority: .low,
            confidence: .high,
            attribution: .personal
        )
    }
    
    // MARK: - Warning Insights
    
    static func paceAccelerated(
        currentPace: Double,
        previousPace: Double
    ) -> HealthspanInsight {
        HealthspanInsight(
            title: "Pace of Aging Elevated",
            message: "Your Pace of Aging (\(String(format: "%.1f", currentPace))x) has increased. This often reflects recent changes in sleep, activity, or recovery patterns.",
            category: .warning,
            priority: .high,
            confidence: .medium,
            attribution: .personal,
            relatedMetrics: ["currentPace": currentPace, "previousPace": previousPace],
            impactOnPace: .major,
            recommendation: "Review your sleep consistency and activity levels from the past week.",
            timeframe: .immediate,
            difficulty: .easy
        )
    }
}

// MARK: - Weekly Summary

struct HealthspanWeeklySummary: Identifiable, Codable {
    let id: UUID
    let weekStartDate: Date
    let weekEndDate: Date
    
    // Changes
    let straynAgeChange: Double        // Delta from last week
    let paceOfAgingChange: Double      // Delta from last week
    
    // Highlights
    let headlineInsight: HealthspanInsight
    let topPositiveFactors: [String]
    let topNegativeFactors: [String]
    
    // Coaching message
    let coachingTitle: String
    let coachingMessage: String
    let weekAhead: String
    
    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        weekEndDate: Date,
        straynAgeChange: Double,
        paceOfAgingChange: Double,
        headlineInsight: HealthspanInsight,
        topPositiveFactors: [String],
        topNegativeFactors: [String],
        coachingTitle: String,
        coachingMessage: String,
        weekAhead: String
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.straynAgeChange = straynAgeChange
        self.paceOfAgingChange = paceOfAgingChange
        self.headlineInsight = headlineInsight
        self.topPositiveFactors = topPositiveFactors
        self.topNegativeFactors = topNegativeFactors
        self.coachingTitle = coachingTitle
        self.coachingMessage = coachingMessage
        self.weekAhead = weekAhead
    }
}
