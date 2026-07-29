//
//  SleepDebtBank.swift
//  strayn
//
//  Created by Aryan Dwivedi on 18/01/26.
//

import Foundation

class SleepDebtBank {
    static let shared = SleepDebtBank()
    
    // MARK: - Sleep Debt
    /// Calculates current sleep debt based on recent history.
    /// Returns debt in seconds (positive value = debt).
    func calculateSleepDebt(recentSessions: [SleepSession], userSleepNeed: TimeInterval = 8.0 * 3600) -> TimeInterval {
        // Simple rolling window model (e.g., last 14 days weighted)
        // Debt = Accumulated (Need - Actual)
        // Decay factor: Recent nights matter more.
        
        var totalDebt: TimeInterval = 0
        
        let sortedSessions = recentSessions.sorted(by: { $0.date > $1.date })
        let maxDays = min(sortedSessions.count, 14)
        
        for i in 0..<maxDays {
            let session = sortedSessions[i]
            let deficit = max(0, userSleepNeed - session.totalDuration)
            
            // Weighting: 1.0 for last night, diminishing by 0.1 per day
            let weight = max(0.1, 1.0 - (Double(i) * 0.05))
            
            totalDebt += deficit * weight
        }
        
        // Cap debt at reasonable limit (e.g. 4 hours) so it's recoverable
        return min(totalDebt, 4.0 * 3600)
    }
    
    // MARK: - Circadian Alignment
    /// Calculates alignment based on sleep midpoint consistency.
    /// Range 0.0 (Poor) to 1.0 (Perfect)
    func calculateCircadianAlignment(sessions: [SleepSession]) -> Double {
        guard sessions.count >= 3 else { return 1.0 } // Assume perfect if no data
        
        // Calculate midpoints (minutes from midnight)
        let midpoints = sessions.compactMap { session -> Double? in
            let start = Calendar.current.component(.hour, from: session.startDate) * 60 + Calendar.current.component(.minute, from: session.startDate)
            let durationMinutes = session.totalDuration / 60.0
            // Normalize start time (if before noon, treat as next day... simplification needed)
            // Ideally use seconds from reference date, but let's effectively use "Minutes past 9PM"
            // Simple approach: Variance of midpoints
            
            // We'll stick to a simpler variance logic for MVP
            // Standard deviation of sleep/wake times?
            
            return nil // TODO: Robust time math needed here
        }
        
        // Simplified Logic: Standard Deviation of Start Times
        // Extract start hour (normalized for late night)
        let startTimes = sessions.map { session -> Double in
            var hour = Double(Calendar.current.component(.hour, from: session.startDate))
            if hour < 12 { hour += 24 } // Treat 1AM as 25
            let minute = Double(Calendar.current.component(.minute, from: session.startDate)) / 60.0
            return hour + minute
        }
        
        let mean = startTimes.reduce(0, +) / Double(startTimes.count)
        let sumSquaredDiffs = startTimes.map { pow($0 - mean, 2) }.reduce(0, +)
        let variance = sumSquaredDiffs / Double(startTimes.count)
        let stdDev = sqrt(variance)
        
        // Interpretation: 
        // StdDev < 0.5 hours (30 mins) -> Great (1.0)
        // StdDev > 2.0 hours -> Poor (0.0)
        
        if stdDev <= 0.5 { return 1.0 }
        if stdDev >= 2.0 { return 0.0 }
        
        // Linear interpolation
        return 1.0 - ((stdDev - 0.5) / 1.5)
    }
}
