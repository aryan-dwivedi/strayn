//
//  RecoveryForecastEngine.swift
//  strayn
//
//  Created by Aryan Dwivedi on 18/01/26.
//

import Foundation

struct ForecastResult {
    let predictedRecovery24h: Double // Next day
    let predictedRecovery48h: Double // Day after
    let recommendation: String
}

class RecoveryForecastEngine {
    static let shared = RecoveryForecastEngine()
    
    func forecastRecovery(
        currentRecovery: Double,
        accumulatedStrain: Double,
        sleepDebt: Double
    ) -> ForecastResult {
        // Simplified degradation model
        // Strain reduces future recovery.
        // Sleep debt reduces future recovery.
        // High current recovery buffers the impact.
        
        // 1. Next Day Forecast
        var baseNextDay = currentRecovery * 0.8 // Regression to mean logic + fatigue
        
        // Strain Impact
        if accumulatedStrain > 15 {
            baseNextDay -= (accumulatedStrain - 15) * 3.0
        } else if accumulatedStrain < 10 {
            baseNextDay += 5.0 // Rest day bonus
        }
        
        // Sleep Debt Impact
        if sleepDebt > 2.0 * 3600 {
             // > 2 hours debt
            baseNextDay -= 10.0
        }
        
        let pred24h = min(max(baseNextDay, 10), 99)
        
        // 2. 48h Forecast
        // Assumes "Normal" strain/sleep for the intermediate day
        var base48h = pred24h * 0.9 + 10.0 // Regression to baseline
        
        let pred48h = min(max(base48h, 10), 99)
        
        // Recommendation
        let message: String
        if pred24h < 40 {
            message = "High risk of low recovery tomorrow. Prioritize sleep tonight."
        } else if pred24h > 80 {
            message = "You are trending towards a peak performance state."
        } else {
            message = "Maintain consistent habits to preserve your momentum."
        }
        
        return ForecastResult(
            predictedRecovery24h: pred24h,
            predictedRecovery48h: pred48h,
            recommendation: message
        )
    }
}
