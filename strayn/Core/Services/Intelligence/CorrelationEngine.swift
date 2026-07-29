//
//  CorrelationEngine.swift
//  strayn
//
//  Analyzes habit entries against health metrics to find correlations.
//

import Foundation

class CorrelationEngine {
    static let shared = CorrelationEngine()
    
    private init() {}
    
    /// Analyzes a set of habit entries against recovery scores to find impact.
    /// Returns a list of habits and their calculated impact on the metric.
    func analyzeHabitImpact(habits: [HabitEntry], recoveries: [DailyRecovery]) -> [String: Double] {
        var habitImpacts: [String: [Double]] = [:]
        
        // Group recovery scores by habit presence
        for habit in habits {
            if let recovery = recoveries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: habit.date) }) {
                if habitImpacts[habit.habitId] == nil {
                    habitImpacts[habit.habitId] = []
                }
                
                // Calculate delta from user average
                let averageRecovery = recoveries.map({ $0.recoveryScore }).reduce(0, +) / Double(recoveries.count)
                let delta = recovery.recoveryScore - averageRecovery
                habitImpacts[habit.habitId]?.append(delta)
            }
        }
        
        // Average the deltas
        var finalCorrelations: [String: Double] = [:]
        for (habitId, deltas) in habitImpacts {
            finalCorrelations[habitId] = deltas.reduce(0, +) / Double(deltas.count)
        }
        
        return finalCorrelations
    }
}
