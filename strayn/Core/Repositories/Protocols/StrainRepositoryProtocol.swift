//
//  StrainRepositoryProtocol.swift
//  strayn
//
//  Protocol defining strain data access operations
//

import Foundation

protocol StrainRepositoryProtocol {
    /// Get strain for a specific date
    func getStrain(for date: Date) async throws -> DailyStrain?

    /// Get strains for a date range
    func getStrains(from startDate: Date, to endDate: Date) async throws -> [DailyStrain]

    /// Get last N days of strain
    func getRecentStrains(days: Int) async throws -> [DailyStrain]

    /// Save strain
    func saveStrain(_ strain: DailyStrain) async throws

    /// Update strain (for real-time updates during the day)
    func updateStrain(_ strain: DailyStrain) async throws

    /// Delete strain
    func deleteStrain(_ strain: DailyStrain) async throws

    /// Delete old strains (cleanup)
    func deleteStrainsOlderThan(days: Int) async throws

    /// Get average strain for a period
    func getAverageStrain(for days: Int) async throws -> Double?

    /// Get today's strain (live updating)
    func getTodayStrain() async throws -> DailyStrain?
}
