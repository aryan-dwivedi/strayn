//
//  DailyInsightService.swift
//  strayn
//
//  Generates personalized health briefs and discovery insights.
//

import Foundation

class DailyInsightService {
    static let shared = DailyInsightService()
    
    private let habitTracker = HabitTrackerService.shared
    
    private init() {}
    
    struct HealthBrief: Codable {
        let title: String
        let summary: String
        let recommendations: [String]
        let correlations: [String]
    }
    
    /// Generates a personalized daily briefing.
    func generateDailyBrief(recovery: DailyRecovery, strain: DailyStrain?) async -> HealthBrief {
        var summary = ""
        var recommendations: [String] = []
        
        let zone = recovery.recoveryZone
        
        switch zone {
        case .green:
            summary = "Your system is firing on all cylinders today. HRV is above baseline, suggesting optimal autonomic readiness."
            recommendations.append("Perfect day for high-intensity training.")
            recommendations.append("Consider a 15-21 strain target.")
        case .yellow:
            summary = "You're in the yellow zone. Your body is maintaining homeostasis but recovery isn't peaks. A moderate load is advised."
            recommendations.append("Stick to functional movements or moderate cardio.")
            recommendations.append("Focus on hydration and early sleep tonight.")
        case .red:
            summary = "Recovery is critically low. We detected a significant HRV suppression which typically indicates high stress or impending illness."
            recommendations.append("Active recovery only (walking, light stretching).")
            recommendations.append("Prioritize magnesium and total rest.")
        }
        
        // Add correlations if available
        let impacts = try? await habitTracker.getImpactAnalysis()
        var correlations: [String] = []
        
        if let alcoholImpact = impacts?["alcohol"], alcoholImpact < -10 {
            correlations.append("Alcohol is suppressing your HRV by an average of \(Int(abs(alcoholImpact)))%.")
        }
        
        if let sleepConsist = impacts?["sleep_consistency"], sleepConsist > 5 {
            correlations.append("Consistent sleep timing is boosting your recovery by \(Int(sleepConsist))%.")
        }
        
        return HealthBrief(
            title: "Morning Brief",
            summary: summary,
            recommendations: recommendations,
            correlations: correlations
        )
    }
}
