//
//  CoachingService.swift
//  strayn
//

import Foundation

class CoachingService {
    static let shared = CoachingService()
    
    private let insightRepo: CoachingInsightRepositoryProtocol
    private let engine = InsightRuleEngine.shared
    
    // In a real app, we'd inject this
    init(insightRepo: CoachingInsightRepositoryProtocol = CoreDataCoachingInsightRepository.shared) {
        self.insightRepo = insightRepo
    }
    
    func updateDailyInsights(
        recovery: DailyRecovery?,
        strain: DailyStrain?,
        sleep: SleepSession?,
        baselines: [Baseline]
    ) async throws {
        let newInsights = engine.generateInsights(
            recovery: recovery,
            strain: strain,
            sleep: sleep,
            baselines: baselines
        )
        
        // Save the top insight for today
        if let topInsight = newInsights.first {
            try await insightRepo.saveInsight(topInsight)
        }
    }
}

// Protocol & Repository implementation placeholder for Coaching Insights
protocol CoachingInsightRepositoryProtocol {
    func getInsights(for date: Date) async throws -> [CoachingInsight]
    func saveInsight(_ insight: CoachingInsight) async throws
}

class CoreDataCoachingInsightRepository: CoachingInsightRepositoryProtocol {
    static let shared = CoreDataCoachingInsightRepository()
    
    func getInsights(for date: Date) async throws -> [CoachingInsight] {
        // Implementation similar to other repos
        return []
    }
    
    func saveInsight(_ insight: CoachingInsight) async throws {
        // Implementation similar to other repos
    }
}
