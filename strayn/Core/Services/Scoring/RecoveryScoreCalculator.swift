//
//  RecoveryScoreCalculator.swift
//  strayn
//
//  Calculates daily recovery score based on health metrics and baselines
//

import Foundation

class RecoveryScoreCalculator {
    static let shared = RecoveryScoreCalculator()
    
    private init() {}
    
    /// Calculate recovery score for a given day
    /// - Parameters:
    ///   - date: The date for which to calculate recovery
    ///   - hrv: Overnight HRV (SDNN) value
    ///   - rhr: Resting Heart Rate value
    ///   - sleepDuration: Sleep duration in seconds
    ///   - respiratoryRate: Overnight respiratory rate
    ///   - hrvBaseline: User's rolling HRV baseline
    ///   - rhrBaseline: User's rolling RHR baseline
    ///   - sleepTarget: User's target sleep duration
    /// - Returns: A DailyRecovery object containing the calculated scores
    func calculateRecovery(
        date: Date,
        hrv: Double?,
        rhr: Double?,
        sleepDuration: TimeInterval?,
        respiratoryRate: Double?,
        hrvBaseline: Baseline?,
        rhrBaseline: Baseline?,
        sleepTarget: TimeInterval = 28800 // 8 hours default
    ) -> DailyRecovery {
        
        // 1. Calculate Component Scores (0-100)
        
        let hrvScore = calculateMetricScore(value: hrv, baseline: hrvBaseline)
        let rhrScore = calculateMetricScore(value: rhr, baseline: rhrBaseline)
        let sleepScore = calculateSleepScore(duration: sleepDuration, target: sleepTarget)
        let respiratoryRateScore = 50.0 // Placeholder for now, can be improved with RR specific logic
        
        // 2. Weighted Average
        // Weights: HRV (50%), RHR (30%), Sleep (20%)
        
        var totalWeightedScore = 0.0
        var totalWeight = 0.0
        
        if let hrvScore = hrvScore {
            totalWeightedScore += hrvScore * 0.5
            totalWeight += 0.5
        }
        
        if let rhrScore = rhrScore {
            totalWeightedScore += rhrScore * 0.3
            totalWeight += 0.3
        }
        
        if let sleepScore = sleepScore {
            totalWeightedScore += sleepScore * 0.2
            totalWeight += 0.2
        }
        
        let finalScore = totalWeight > 0 ? (totalWeightedScore / totalWeight) : 0.0
        
        return DailyRecovery(
            date: date,
            recoveryScore: finalScore,
            recoveryZone: DailyRecovery.RecoveryZone.zone(for: finalScore),
            hrvScore: hrvScore ?? 0,
            restingHRScore: rhrScore ?? 0,
            sleepScore: sleepScore ?? 0,
            respiratoryRateScore: respiratoryRateScore,
            rawHRV: hrv,
            rawRestingHR: rhr,
            rawSleepDuration: sleepDuration,
            rawRespiratoryRate: respiratoryRate,
            hrvBaseline: hrvBaseline?.mean,
            restingHRBaseline: rhrBaseline?.mean,
            hasInsufficientData: totalWeight < 0.5
        )
    }
    
    /// Normalizes a metric value against its baseline to a 0-100 score
    private func calculateMetricScore(value: Double?, baseline: Baseline?) -> Double? {
        guard let value = value, let baseline = baseline, baseline.standardDeviation > 0 else {
            return nil
        }
        
        // Z-score calculation
        let zScore = (value - baseline.mean) / baseline.standardDeviation
        
        // Map Z-score to 0-100
        // We assume +/- 3 Standard Deviations covers most cases
        // Z-score of 0 (at mean) = 50
        // Z-score of +2 (well above mean) = 90
        // Z-score of -2 (well below mean) = 10
        
        var score: Double
        if baseline.metric.higherIsBetter {
            score = 50.0 + (zScore * 20.0)
        } else {
            // Inverted for RHR, Respiratory Rate etc.
            score = 50.0 - (zScore * 20.0)
        }
        
        return max(0, min(100, score))
    }
    
    private func calculateSleepScore(duration: TimeInterval?, target: TimeInterval) -> Double? {
        guard let duration = duration, target > 0 else {
            return nil
        }
        
        // Simple percentage of target, capped at 100
        let score = (duration / target) * 100.0
        return max(0, min(100, score))
    }
}
