//
//  SleepRepositoryProtocol.swift
//  strayn
//
//  Protocol defining sleep data access operations
//

import Foundation

protocol SleepRepositoryProtocol {
    /// Get last sleep session (most recent)
    func getLastSleep() async throws -> SleepSession?

    /// Get sleep session for a specific date (night ending on that date)
    func getSleep(for date: Date) async throws -> SleepSession?

    /// Get sleep sessions for a date range
    func getSleepSessions(from startDate: Date, to endDate: Date) async throws -> [SleepSession]

    /// Get last N sleep sessions
    func getRecentSleepSessions(count: Int) async throws -> [SleepSession]

    /// Save sleep session
    func saveSleepSession(_ session: SleepSession) async throws

    /// Delete sleep session
    func deleteSleepSession(_ session: SleepSession) async throws

    /// Calculate rolling sleep debt (last 7 days)
    func calculateSleepDebt() async throws -> TimeInterval

    /// Get average sleep duration for a period
    func getAverageSleepDuration(for days: Int) async throws -> TimeInterval?

    /// Get sleep efficiency trend
    func getAverageSleepEfficiency(for days: Int) async throws -> Double?
}
