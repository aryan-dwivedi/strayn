//
//  BaselineRepositoryProtocol.swift
//  strayn
//
//  Protocol defining baseline data access operations
//

import Foundation

protocol BaselineRepositoryProtocol {
    /// Get current baseline for a metric
    func getBaseline(for metric: Baseline.BaselineMetric, userId: UUID) async throws -> Baseline?

    /// Get all baselines for a user
    func getAllBaselines(for userId: UUID) async throws -> [Baseline]

    /// Save baseline
    func saveBaseline(_ baseline: Baseline) async throws

    /// Delete baseline
    func deleteBaseline(_ baseline: Baseline) async throws

    /// Get baseline history for trend analysis
    func getBaselineHistory(
        for metric: Baseline.BaselineMetric,
        userId: UUID,
        limit: Int
    ) async throws -> [Baseline]
}
