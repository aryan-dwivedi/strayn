//
//  SleepBankService.swift
//  strayn
//
//  Tracks rolling sleep debt and circadian alignment.
//

import Foundation

class SleepBankService {
    static let shared = SleepBankService()
    
    private let sleepRepo = CoreDataSleepRepository.shared
    
    private init() {}
    
    /// Calculates the rolling sleep debt over the last 14 days (in seconds).
    func calculateRollingSleepDebt(days: Int = 14) async -> TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var totalDebt: TimeInterval = 0
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: today),
               let sleep = try? await sleepRepo.getSleep(for: date) {
                let debtForDay = max(0, sleep.sleepNeed - sleep.totalDuration)
                totalDebt += debtForDay
            }
        }
        
        return totalDebt
    }
    
    /// Returns a score (0-100) representing sleep consistency.
    func calculateConsistencyScore(days: Int = 7) async -> Double {
        // Logic would compare startTime and duration variance
        // Placeholder for now
        return Double.random(in: 70...95)
    }
}
