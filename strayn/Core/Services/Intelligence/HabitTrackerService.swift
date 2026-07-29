//
//  HabitTrackerService.swift
//  strayn
//
//  Orchestrates habit tracking and correlation analysis.
//

import Foundation

class HabitTrackerService {
    static let shared = HabitTrackerService()
    
    private let habitRepo = CoreDataHabitRepository.shared
    private let recoveryRepo = CoreDataRecoveryRepository.shared
    private let correlationEngine = CorrelationEngine.shared
    
    private init() {}
    
    func logHabit(id: String, value: String, date: Date = Date()) async throws {
        let entry = HabitEntry(
            id: UUID(),
            habitId: id,
            date: date,
            value: value,
            timestamp: Date()
        )
        try await habitRepo.saveHabitEntry(entry)
    }
    
    func getImpactAnalysis() async throws -> [String: Double] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        
        let habits = try await habitRepo.getHabitEntries(from: thirtyDaysAgo, to: Date())
        let recoveries = try await recoveryRepo.getRecoveries(from: thirtyDaysAgo, to: Date())
        
        return correlationEngine.analyzeHabitImpact(habits: habits, recoveries: recoveries)
    }
}
