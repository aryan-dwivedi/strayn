//
//  RecoveryRepositoryProtocol.swift
//  strayn
//
//  Protocol defining recovery data access operations
//

import Foundation

protocol RecoveryRepositoryProtocol {
    /// Get recovery for a specific date
    func getRecovery(for date: Date) async throws -> DailyRecovery?

    /// Get recoveries for a date range
    func getRecoveries(from startDate: Date, to endDate: Date) async throws -> [DailyRecovery]

    /// Get last N days of recovery
    func getRecentRecoveries(days: Int) async throws -> [DailyRecovery]

    /// Save recovery
    func saveRecovery(_ recovery: DailyRecovery) async throws

    /// Delete recovery
    func deleteRecovery(_ recovery: DailyRecovery) async throws

    /// Delete old recoveries (cleanup)
    func deleteRecoveriesOlderThan(days: Int) async throws

    /// Get average recovery for a period
    func getAverageRecovery(for days: Int) async throws -> Double?
}
