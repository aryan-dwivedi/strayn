//
//  InsightRuleEngine.swift
//  strayn
//
//  Generates personalized coaching insights based on user data
//

import Foundation

class InsightRuleEngine {
    static let shared = InsightRuleEngine()
    
    private init() {}
    
    /// Evaluate all rules and return prioritized insights
    func generateInsights(
        recovery: DailyRecovery?,
        strain: DailyStrain?,
        sleep: SleepSession?,
        baselines: [Baseline]
    ) -> [CoachingInsight] {
        var insights: [CoachingInsight] = []
        let today = Date()
        
        // Rule: Low Recovery + High Strain Prediction (Overreaching)
        if let recovery = recovery, recovery.recoveryScore < 33 {
            insights.append(CoachingInsight(
                date: today,
                title: "Prioritize Recovery",
                message: "Your recovery is low today. Keep activity light to avoid overtraining and allow your body to bounce back.",
                category: .recovery,
                priority: 10
            ))
        }
        
        // Rule: High Recovery (Ready for challenge)
        if let recovery = recovery, recovery.recoveryScore > 66 {
            insights.append(CoachingInsight(
                date: today,
                title: "Ready to Push",
                message: "Your body is primed for stress today. This is an ideal time for a high-intensity session or a long endurance effort.",
                category: .strain,
                priority: 8
            ))
        }
        
        // Rule: Sleep Debt Alert
        if let sleep = sleep, sleep.sleepDebt > 7200 { // 2 hours
            insights.append(CoachingInsight(
                date: today,
                title: "Sleep Debt Building",
                message: "You've accumulated over 2 hours of sleep debt recently. Aim for an earlier bedtime tonight to restore your baseline.",
                category: .sleep,
                priority: 7
            ))
        }
        
        // Rule: HRV Trend Improving
        if let hrvBaseline = baselines.first(where: { $0.metric == .hrv }), hrvBaseline.trend == .improving {
            insights.append(CoachingInsight(
                date: today,
                title: "Fitness Improving",
                message: "Your HRV baseline is trending upwards, indicating a positive adaptation to your recent training load.",
                category: .adaptation,
                priority: 6
            ))
        }
        
        // Sort by priority
        return insights.sorted { $0.priority > $1.priority }
    }
}
