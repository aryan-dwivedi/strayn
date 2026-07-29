//
//  InsightEngine.swift
//  strayn
//
//  Created by Aryan Dwivedi on 18/01/26.
//

import Foundation

struct HealthBrief {
    let title: String
    let summary: String
    let recommendations: [String]
    let correlations: [String]
}

class InsightEngine {
    static let shared = InsightEngine()
    
    func generateDailyBrief(recovery: DailyRecovery?, strain: DailyStrain?, sleep: SleepSession?) -> HealthBrief {
        guard let recovery = recovery else {
            return HealthBrief(title: "Welcome to Strayn", summary: "Start wearing your device to sleep to unlock insights.", recommendations: [], correlations: [])
        }
        
        var title = "Ready to Perform"
        var summary = "Your recovery is excellent. Your physiological markers indicate you are primed for high strain today."
        var recommendations: [String] = ["Push hard in your workout", "Hydrate to maintain status"]
        
        if recovery.recoveryScore < 40 {
            title = "Focus on Rest"
            summary = "Your autonomic nervous system is stressed. Your HRV dropped significantly compared to your 30-day baseline."
            recommendations = ["Prioritize sleep tonight", "Avoid high intensity training", "Try a NSDR session"]
        } else if recovery.recoveryScore < 70 {
            title = "Maintain Balance"
            summary = "You are in a maintenance zone. Strain is okay, but listen to your body signals."
            recommendations = ["Moderate exercise recommended", "Get sunlight early"]
        }
        
        // Check specific contributors
        if let sleep = sleep, sleep.totalDuration < 7 * 3600 {
            summary += " Sleep duration was the main limiting factor."
        }
        
        // Convert HabitCorrelations to string descriptions
        let habitCorrelations = HabitTracker.shared.analyzeCorrelations(habitHistory: [:], recoveryHistory: [:])
        let correlationStrings = habitCorrelations.map { "\($0.habitName): \($0.formattedImpact)" }

        return HealthBrief(
            title: title,
            summary: summary,
            recommendations: recommendations,
            correlations: correlationStrings
        )
    }
}
