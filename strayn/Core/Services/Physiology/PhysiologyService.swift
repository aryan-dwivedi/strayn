//
//  PhysiologyService.swift
//  strayn
//
//  Created by Aryan Dwivedi on 18/01/26.
//

import Foundation

class PhysiologyService {
    static let shared = PhysiologyService()
    
    // MARK: - Autonomic Balance
    /// Calculates Autonomic Balance based on HRV trend.
    /// Range: 0.0 (Sympathetic Dominance) to 1.0 (Parasympathetic Dominance)
    func calculateAutonomicBalance(currentHRV: Double, baselineHRV: Double) -> Double {
        // Simple ratio model: if current > baseline, likely parasympathetic dominant.
        // if current < baseline, sympathetic (stress) dominant.
        let ratio = currentHRV / baselineHRV
        
        // Normalize to 0...1 range loosely centered on 0.5 for baseline
        if ratio >= 1.0 {
            // Above baseline: 0.5 ... 1.0
            return min(0.5 + (ratio - 1.0) * 0.5, 1.0)
        } else {
            // Below baseline: 0.0 ... 0.5
            return max(0.5 - (1.0 - ratio) * 0.8, 0.0)
        }
    }
    
    // MARK: - Stress Load
    /// Computes Stress Load Index based on HR elevation and HRV suppression.
    /// Range: 0 (Low Stress) to 100 (High Stress)
    func calculateStressLoad(restingHR: Double, baselineRHR: Double, hrv: Double, baselineHRV: Double) -> Double {
        var score = 0.0
        
        // 1. HR Contribution (50%)
        if restingHR > baselineRHR {
            let hrElevation = restingHR - baselineRHR
            // Example: 10bpm increase = high stress contribution
            score += min((hrElevation / 15.0) * 50.0, 50.0)
        }
        
        // 2. HRV Contribution (50%)
        if hrv < baselineHRV {
            let hrvSuppression = baselineHRV - hrv
            // Example: 20ms drop = high stress contribution
            score += min((hrvSuppression / 30.0) * 50.0, 50.0)
        }
        
        return min(max(score, 0), 100)
    }
    
    // MARK: - Recovery Calculation
    func calculateRecoveryScore(
        sleepPerformance: Double, // 0-100
        hrvScore: Double, // Normalized 0-100
        rhrScore: Double, // Normalized 0-100
        autonomicBalance: Double,
        stressLoad: Double
    ) -> Double {
        // Weighted contributions
        let sleepWeight = 0.4
        let hrvWeight = 0.35
        let rhrWeight = 0.15
        let autonomicWeight = 0.1
        
        var score = (sleepPerformance * sleepWeight) +
                    (hrvScore * hrvWeight) +
                    (rhrScore * rhrWeight) +
                    (autonomicBalance * 100.0 * autonomicWeight)
        
        // Penalize for high stress load
        if stressLoad > 60 {
            score -= (stressLoad - 60) * 0.5
        }
        
        return min(max(score, 1), 99)
    }
}
