//
//  HealthspanInsightEngine.swift
//  strayn
//
//  Generates natural-language insights for Healthspan based on
//  Strayn Age, Pace of Aging, and underlying metric patterns.
//

import Foundation

// MARK: - Healthspan Insight Engine

final class HealthspanInsightEngine {
    
    // MARK: - Shared Instance
    
    static let shared = HealthspanInsightEngine()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Main Generation Method
    
    func generateInsights(
        healthspan: Healthspan,
        previousHealthspan: Healthspan?,
        inputData: StraynAgeInputData?
    ) -> [HealthspanInsight] {
        
        var insights: [HealthspanInsight] = []
        
        // 1. Generate weekly summary insight
        if let previous = previousHealthspan {
            insights.append(contentsOf: generateWeeklyChangeInsights(
                current: healthspan,
                previous: previous
            ))
        }
        
        // 2. Generate pace-based insights
        insights.append(contentsOf: generatePaceInsights(pace: healthspan.paceOfAging))
        
        // 3. Generate age component insights
        insights.append(contentsOf: generateAgeComponentInsights(straynAge: healthspan.straynAge))
        
        // 4. Generate pillar-specific insights from input data
        if let input = inputData {
            insights.append(contentsOf: generatePillarInsights(input: input, pace: healthspan.paceOfAging))
        }
        
        // 5. Generate milestone insights
        insights.append(contentsOf: generateMilestoneInsights(
            healthspan: healthspan,
            previous: previousHealthspan
        ))
        
        // Sort by priority and return
        return insights.sorted { $0.priority < $1.priority }
    }
    
    // MARK: - Weekly Change Insights
    
    private func generateWeeklyChangeInsights(
        current: Healthspan,
        previous: Healthspan
    ) -> [HealthspanInsight] {
        
        var insights: [HealthspanInsight] = []
        
        let ageChange = current.straynAge.age - previous.straynAge.age
        let paceChange = current.paceOfAging.pace - previous.paceOfAging.pace
        
        // Strayn Age change
        if abs(ageChange) >= 0.1 {
            if ageChange < 0 {
                insights.append(HealthspanInsight.straynAgeImproved(
                    previousAge: previous.straynAge.age,
                    currentAge: current.straynAge.age
                ))
            } else {
                insights.append(HealthspanInsight(
                    title: "Strayn Age Increased",
                    message: "Your Strayn Age increased by \(String(format: "%.1f", ageChange)) years this week. Review the contributing factors below for improvement opportunities.",
                    category: .straynAge,
                    priority: .medium,
                    confidence: .high,
                    attribution: .personal,
                    relatedMetrics: ["change": ageChange],
                    impactOnStraynAge: .moderate
                ))
            }
        }
        
        // Pace change
        if abs(paceChange) >= 0.1 {
            if paceChange < 0 {
                insights.append(HealthspanInsight(
                    title: "Pace of Aging Improving",
                    message: "Your Pace of Aging decreased by \(String(format: "%.1f", abs(paceChange)))x this week. Your recent habits are supporting longevity.",
                    category: .paceOfAging,
                    priority: .medium,
                    confidence: .high,
                    attribution: .personal,
                    impactOnPace: .moderate
                ))
            } else {
                insights.append(HealthspanInsight.paceAccelerated(
                    currentPace: current.paceOfAging.pace,
                    previousPace: previous.paceOfAging.pace
                ))
            }
        }
        
        return insights
    }
    
    // MARK: - Pace Insights
    
    private func generatePaceInsights(pace: PaceOfAging) -> [HealthspanInsight] {
        var insights: [HealthspanInsight] = []
        
        // Zone-specific insight
        switch pace.zone {
        case .optimal:
            insights.append(HealthspanInsight.paceOptimalAchieved())
            
        case .slow:
            insights.append(HealthspanInsight(
                title: "Slow Pace of Aging",
                message: pace.zone.description,
                category: .paceOfAging,
                priority: .low,
                confidence: .high,
                attribution: .personal,
                recommendation: pace.zone.recommendation,
                timeframe: .longTerm
            ))
            
        case .steady:
            insights.append(HealthspanInsight(
                title: "Steady Pace",
                message: pace.zone.description,
                category: .paceOfAging,
                priority: .informational,
                confidence: .high,
                attribution: .personal,
                recommendation: pace.zone.recommendation,
                timeframe: .thisMonth
            ))
            
        case .elevated:
            insights.append(HealthspanInsight(
                title: "Elevated Pace of Aging",
                message: pace.zone.description,
                category: .warning,
                priority: .high,
                confidence: .medium,
                attribution: .personal,
                recommendation: pace.zone.recommendation,
                timeframe: .thisWeek,
                difficulty: .easy
            ))
            
        case .accelerated:
            insights.append(HealthspanInsight(
                title: "Accelerated Pace - Action Needed",
                message: pace.zone.description,
                category: .warning,
                priority: .critical,
                confidence: .medium,
                attribution: .personal,
                recommendation: pace.zone.recommendation,
                timeframe: .immediate,
                difficulty: .moderate
            ))
        }
        
        // Driver-based insights
        for driver in pace.primaryDrivers.prefix(2) {
            if driver.direction == .accelerating && driver.magnitude != .minor {
                insights.append(HealthspanInsight(
                    title: "\(driver.metric) Concern",
                    message: driver.explanation,
                    category: categoryForPillar(driver.pillar),
                    priority: driver.magnitude == .major ? .high : .medium,
                    confidence: .medium,
                    attribution: .personal,
                    relatedPillar: driver.pillar,
                    impactOnPace: driver.magnitude == .major ? .major : .moderate,
                    recommendation: driver.actionableInsight,
                    timeframe: .thisWeek,
                    difficulty: .easy
                ))
            }
        }
        
        return insights
    }
    
    // MARK: - Age Component Insights
    
    private func generateAgeComponentInsights(straynAge: StraynAge) -> [HealthspanInsight] {
        var insights: [HealthspanInsight] = []
        
        // Identify most impactful components
        let sortedComponents = straynAge.componentsSortedByImpact
        
        // Best performing component
        if let best = sortedComponents.last, best.ageDelta < -0.5 {
            insights.append(HealthspanInsight(
                title: "\(best.name) System Strong",
                message: "Your \(best.name.lowercased()) metrics are making you \(String(format: "%.1f", abs(best.ageDelta))) years younger. This is your strongest pillar.",
                category: categoryForComponent(best.name),
                priority: .low,
                confidence: .high,
                attribution: .personal,
                impactOnStraynAge: .moderate
            ))
        }
        
        // Worst performing component (if it's adding years)
        if let worst = sortedComponents.first, worst.ageDelta > 0.5 {
            let recommendation = recommendationForComponent(worst)
            insights.append(HealthspanInsight(
                title: "\(worst.name) System Needs Attention",
                message: "Your \(worst.name.lowercased()) metrics are adding \(String(format: "%.1f", worst.ageDelta)) years to your Strayn Age. This is your biggest opportunity for improvement.",
                category: categoryForComponent(worst.name),
                priority: .medium,
                confidence: .medium,
                attribution: .combined,
                impactOnStraynAge: .major,
                recommendation: recommendation,
                timeframe: .thisMonth,
                difficulty: .moderate
            ))
        }
        
        // Individual driver insights for concerning metrics
        for driver in straynAge.topNegativeDrivers.prefix(2) {
            insights.append(HealthspanInsight(
                title: "\(driver.metric) Impact",
                message: driver.explanation,
                category: .straynAge,
                priority: .medium,
                confidence: .medium,
                attribution: .combined,
                relatedMetrics: driver.value.map { [driver.metric: $0] } ?? [:],
                impactOnStraynAge: driver.impact == .veryNegative ? .major : .moderate,
                recommendation: driver.optimalRange.map { "Aim for \($0)" }
            ))
        }
        
        return insights
    }
    
    // MARK: - Pillar-Specific Insights
    
    private func generatePillarInsights(
        input: StraynAgeInputData,
        pace: PaceOfAging
    ) -> [HealthspanInsight] {
        
        var insights: [HealthspanInsight] = []
        
        // Sleep insights
        if let sleepDuration = input.averageSleepDuration {
            let hours = sleepDuration / 3600
            if hours < 6.5 {
                insights.append(HealthspanInsight.sleepDurationLow(
                    averageDuration: sleepDuration,
                    targetDuration: 7.5 * 3600
                ))
            }
        }
        
        if let consistency = input.sleepConsistencyScore, consistency >= 75 {
            insights.append(HealthspanInsight.sleepConsistencyImproving(
                consistencyScore: consistency,
                paceImpact: pace.sleepPace.changeFromBaseline
            ))
        }
        
        // Activity insights
        if let aerobic = input.weeklyModerateAerobicMinutes {
            if aerobic >= 150 {
                insights.append(HealthspanInsight.aerobicActivityExcellent(weeklyMinutes: aerobic))
            }
        }
        
        if let strength = input.weeklyStrengthTrainingMinutes, strength < 30 {
            insights.append(HealthspanInsight.strengthTrainingLow(weeklyMinutes: strength))
        }
        
        // Cardiovascular insights
        if let rhr = input.restingHeartRateAverage,
           let trend = input.restingHeartRateTrend,
           trend == .improving {
            // Find baseline from the input context (simplified)
            let baseline = rhr + 3  // Approximate
            insights.append(HealthspanInsight.restingHRImproving(
                current: rhr,
                baseline: baseline
            ))
        }
        
        // HRV insights
        if let hrv = input.hrvAverage,
           let trend = input.hrvTrend,
           trend == .improving {
            let baseline = hrv - 5  // Approximate
            insights.append(HealthspanInsight.hrvTrendingUp(
                current: hrv,
                baseline: baseline
            ))
        }
        
        return insights
    }
    
    // MARK: - Milestone Insights
    
    private func generateMilestoneInsights(
        healthspan: Healthspan,
        previous: Healthspan?
    ) -> [HealthspanInsight] {
        
        var insights: [HealthspanInsight] = []
        
        // First time in optimal zone
        if healthspan.paceOfAging.zone == .optimal {
            if let prev = previous, prev.paceOfAging.zone != .optimal {
                insights.append(HealthspanInsight(
                    title: "🎉 Optimal Zone Achieved!",
                    message: "Congratulations! You've reached the optimal Pace of Aging zone for the first time. Your dedication to healthy habits is paying off.",
                    category: .milestone,
                    priority: .low,
                    confidence: .high,
                    attribution: .personal
                ))
            }
        }
        
        // Strayn Age milestone (every year younger threshold)
        let ageDelta = healthspan.straynAge.ageDelta
        if ageDelta <= -2.0 {
            insights.append(HealthspanInsight(
                title: "2+ Years Younger!",
                message: "Your Strayn Age is now more than 2 years younger than your chronological age. This reflects exceptional long-term health behaviors.",
                category: .milestone,
                priority: .informational,
                confidence: .high,
                attribution: .personal
            ))
        }
        
        // Calibration milestones
        if case .calibrating(let phase) = healthspan.state {
            if case .partial(let days, _) = phase, days == 21 {
                insights.append(HealthspanInsight(
                    title: "Healthspan Unlocked!",
                    message: "You've tracked enough data to unlock Healthspan. Your Strayn Age will become more accurate as calibration continues.",
                    category: .milestone,
                    priority: .low,
                    confidence: .high,
                    attribution: .personal
                ))
            }
        }
        
        return insights
    }
    
    // MARK: - Weekly Summary Generation
    
    func generateWeeklySummary(
        healthspan: Healthspan,
        previous: Healthspan?,
        insights: [HealthspanInsight]
    ) -> HealthspanWeeklySummary {
        
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(byAdding: .day, value: -7, to: now)!
        
        let ageChange = previous.map { healthspan.straynAge.age - $0.straynAge.age } ?? 0
        let paceChange = previous.map { healthspan.paceOfAging.pace - $0.paceOfAging.pace } ?? 0
        
        // Collect positive factors
        let positiveFactors = healthspan.paceOfAging.positiveDrivers.map { $0.metric }
        let negativeFactors = healthspan.paceOfAging.negativeDrivers.map { $0.metric }
        
        // Generate headline insight
        let headlineInsight = insights.first ?? HealthspanInsight(
            title: "Weekly Health Update",
            message: "Your Healthspan metrics have been updated for this week.",
            category: .straynAge,
            priority: .informational,
            confidence: .high,
            attribution: .personal
        )
        
        // Generate coaching message
        let (coachingTitle, coachingMessage, weekAhead) = generateCoachingMessage(
            pace: healthspan.paceOfAging,
            ageChange: ageChange,
            paceChange: paceChange
        )
        
        return HealthspanWeeklySummary(
            weekStartDate: weekStart,
            weekEndDate: now,
            straynAgeChange: ageChange,
            paceOfAgingChange: paceChange,
            headlineInsight: headlineInsight,
            topPositiveFactors: positiveFactors,
            topNegativeFactors: negativeFactors,
            coachingTitle: coachingTitle,
            coachingMessage: coachingMessage,
            weekAhead: weekAhead
        )
    }
    
    // MARK: - Helpers
    
    private func categoryForPillar(_ pillar: PaceOfAging.PillarPace.Pillar) -> HealthspanInsight.InsightCategory {
        switch pillar {
        case .sleep: return .sleep
        case .activity: return .activity
        case .cardiovascular: return .cardiovascular
        case .recovery: return .recovery
        }
    }
    
    private func categoryForComponent(_ name: String) -> HealthspanInsight.InsightCategory {
        switch name.lowercased() {
        case "cardiovascular": return .cardiovascular
        case "autonomic": return .recovery
        case "sleep": return .sleep
        case "metabolic": return .activity
        default: return .straynAge
        }
    }
    
    private func recommendationForComponent(_ component: StraynAge.AgeComponent) -> String {
        switch component.name.lowercased() {
        case "cardiovascular":
            return "Focus on regular aerobic exercise and monitor your resting heart rate trends."
        case "autonomic":
            return "Prioritize recovery, manage stress, and ensure consistent quality sleep."
        case "sleep":
            return "Work on sleep consistency, duration (7-9hrs), and sleep hygiene practices."
        case "metabolic":
            return "Increase weekly activity minutes and consider adding strength training."
        default:
            return "Review your habits in this area for improvement opportunities."
        }
    }
    
    private func generateCoachingMessage(
        pace: PaceOfAging,
        ageChange: Double,
        paceChange: Double
    ) -> (title: String, message: String, weekAhead: String) {
        
        switch pace.zone {
        case .optimal:
            return (
                "As Good As It Gets",
                "Your WHOOP Age is younger by \(String(format: "%.1f", abs(ageChange))) this week and your Pace of Aging is slow. Both have improved this week showing your commitment to your long term health. Keep up the great work.",
                "Maintain your excellent habits this week. You're maximizing your longevity potential."
            )
            
        case .slow:
            return (
                "Steady and Healthy",
                "Your Strayn Age is younger and your Pace of Aging is slow, thanks to your consistent healthy behaviors. You're doing well, continue your current habits to keep this steady Pace of Aging.",
                "Keep building on your momentum. Small improvements compound over time."
            )
            
        case .steady:
            return (
                "On Track",
                "Your Pace of Aging is steady, meaning your biological age is tracking with time. This is a solid foundation to build on.",
                "Consider focusing on one area this week - sleep consistency or adding an extra cardio session."
            )
            
        case .elevated:
            return (
                "Get Back On Track",
                "Your Pace of Aging is still slow, signaling you're on the right track for long term progress. However, your Strayn Age has increased by \(String(format: "%.1f", abs(ageChange))). Be mindful of your \(pace.mostConcerningPillar?.pillar.rawValue ?? "habits"), as it had the largest negative change this week.",
                "Focus on recovery this week. Even small improvements in sleep can make a difference."
            )
            
        case .accelerated:
            return (
                "Time to Refocus",
                "Your Pace of Aging is elevated this week. This often reflects recent lifestyle changes. Review your sleep patterns and activity levels.",
                "Prioritize sleep and gentle movement this week. Avoid overtraining and focus on recovery."
            )
        }
    }
}
