//
//  SleepPerformanceCalculator.swift
//  strayn
//
//  Calculates sleep debt, efficiency, and performance scores
//

import Foundation

class SleepPerformanceCalculator {
    static let shared = SleepPerformanceCalculator()
    
    private init() {}
    
    /// Calculate sleep performance for a session against a target
    /// - Parameters:
    ///   - session: The sleep session data
    ///   - targetDuration: The user's target sleep duration
    ///   - previousDebt: Current accumulated sleep debt
    /// - Returns: A tuple containing the performance score (0-100) and updated debt
    func calculatePerformance(
        session: SleepSession,
        targetDuration: TimeInterval,
        previousDebt: TimeInterval
    ) -> (score: Double, updatedDebt: TimeInterval) {
        
        let actualDuration = session.totalDuration
        
        // 1. Efficiency Score (0-100)
        // HK already provides efficiency, but we can also use it to scale duration
        let efficiency = session.sleepEfficiency // e.g., 0.92
        let effectiveDuration = actualDuration * efficiency
        
        // 2. Duration Score (0-100)
        let durationScore = min(100.0, (effectiveDuration / targetDuration) * 100.0)
        
        // 3. Consistency Score (0-100)
        // Ideally we compare start times, but for now we'll focus on duration
        
        // 4. Update Sleep Debt
        // Debt is (Target - Actual). If negative, it's "credit" (we cap credit at 2 hours)
        let sessionDebt = targetDuration - actualDuration
        let newDebt = max(-7200, previousDebt + sessionDebt) // Max 2 hours credit
        
        return (durationScore, newDebt)
    }
    
    /// Predicts recovery improvement based on meeting sleep target
    func predictRecoveryBenefit(currentDebt: TimeInterval, nextNightTarget: TimeInterval) -> Double {
        // Simple heuristic: Every hour of debt reduces recovery by ~5%
        // Reducing debt by 2 hours could improve recovery by ~10%
        let debtInHours = currentDebt / 3600.0
        return max(0, min(15.0, debtInHours * 2.5))
    }
}
