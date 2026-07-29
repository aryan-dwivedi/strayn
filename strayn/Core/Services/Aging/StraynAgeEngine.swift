//
//  StraynAgeEngine.swift
//  strayn
//
//  Calculates biological aging metrics based on health trends.
//

import Foundation

class StraynAgeEngine {
    static let shared = StraynAgeEngine()
    
    private init() {}
    
    /// Calculates the "Strayn Age" (Biological Age) based on various health markers.
    func calculateStraynAge(chronologicalAge: Int, rhr: Double, hrv: Double, sleepEfficiency: Double, vo2Max: Double?) -> Double {
        // 1. Cardiovascular Delta
        // Typical RHR for age 30 is ~65. Every 5bpm lower is roughly -1 year.
        let rhrBaselineForAge = 65.0 + (Double(chronologicalAge - 30) * 0.1)
        let cardioDelta = (rhr - rhrBaselineForAge) / 5.0
        
        // 2. Autonomic Delta
        // Higher HRV is younger. Every 10ms above age norm is roughly -1 year.
        let hrvBaselineForAge = 70.0 - (Double(chronologicalAge - 30) * 0.5)
        let autonomicDelta = (hrvBaselineForAge - hrv) / 10.0
        
        // 3. Sleep Delta
        // 90% efficiency is standard. Every 5% difference is +/- 1 year.
        let sleepDelta = (0.90 - sleepEfficiency) / 0.05
        
        // 4. VO2 Max Delta
        // Avg VO2 max for age 30 is ~45. Every 3 points difference is +/- 1 year.
        var vo2Delta = 0.0
        if let vo2 = vo2Max {
            let vo2Baseline = 45.0 - (Double(chronologicalAge - 30) * 0.3)
            vo2Delta = (vo2Baseline - vo2) / 3.0
        }
        
        let totalDelta = cardioDelta + autonomicDelta + sleepDelta + vo2Delta
        return Double(chronologicalAge) + totalDelta
    }
    
    /// Provides specific age breakdowns for different systems.
    func calculateAgeSystems(chronologicalAge: Int, rhr: Double, hrv: Double, sleepEfficiency: Double, vo2Max: Double?) -> [String: Double] {
        let cardio = Double(chronologicalAge) + ((rhr - 65.0) / 5.0)
        let autonomic = Double(chronologicalAge) + ((70.0 - hrv) / 10.0)
        let sleep = Double(chronologicalAge) + ((0.90 - sleepEfficiency) / 0.05)
        
        var systems = [
            "Cardiovascular": cardio,
            "Autonomic": autonomic,
            "Sleep resilience": sleep
        ]
        
        if let vo2 = vo2Max {
            let metabolic = Double(chronologicalAge) + ((45.0 - vo2) / 3.0)
            systems["Metabolic"] = metabolic
        }
        
        return systems
    }
}
