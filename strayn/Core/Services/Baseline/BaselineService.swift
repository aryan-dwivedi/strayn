//
//  BaselineService.swift
//  strayn
//
//  Calculates and updates rolling baselines for health metrics
//

import Foundation

class BaselineService {
    static let shared = BaselineService()
    
    // Repositories would be injected normally, but for MVP we might access them via a container
    // For this service implementation, we'll assume they are provided or accessible
    
    private init() {}
    
    /// Update baselines for all core metrics for a user
    func updateAllBaselines(
        userId: UUID,
        recoveryRepo: RecoveryRepositoryProtocol,
        sleepRepo: SleepRepositoryProtocol,
        baselineRepo: BaselineRepositoryProtocol
    ) async throws {
        
        // 1. Update HRV and RHR baselines from recovery data
        let recentRecoveries = try await recoveryRepo.getRecentRecoveries(days: 30)
        
        try await updateMetricBaseline(
            userId: userId,
            metric: .hrv,
            values: recentRecoveries.compactMap { $0.rawHRV },
            dates: recentRecoveries.map { $0.date },
            repo: baselineRepo
        )
        
        try await updateMetricBaseline(
            userId: userId,
            metric: .restingHR,
            values: recentRecoveries.compactMap { $0.rawRestingHR },
            dates: recentRecoveries.map { $0.date },
            repo: baselineRepo
        )
        
        try await updateMetricBaseline(
            userId: userId,
            metric: .respiratoryRate,
            values: recentRecoveries.compactMap { $0.rawRespiratoryRate },
            dates: recentRecoveries.map { $0.date },
            repo: baselineRepo
        )
        
        // 2. Update Sleep Duration baseline
        let recentSleep = try await sleepRepo.getRecentSleepSessions(count: 30)
        
        try await updateMetricBaseline(
            userId: userId,
            metric: .sleepDuration,
            values: recentSleep.map { $0.totalDuration / 3600.0 }, // Convert to hours
            dates: recentSleep.map { $0.date },
            repo: baselineRepo
        )
    }
    
    /// Calculates mean, SD and trend for a set of values and saves to repo
    private func updateMetricBaseline(
        userId: UUID,
        metric: Baseline.BaselineMetric,
        values: [Double],
        dates: [Date],
        repo: BaselineRepositoryProtocol,
        windowDays: Int = 21
    ) async throws {
        
        guard values.count >= 7 else { return } // Need at least a week of data
        
        // 1. Filter outliers (1.5 * IQR)
        let filteredValues = filterOutliers(values)
        guard !filteredValues.isEmpty else { return }
        
        // 2. Calculate Stats
        let mean = filteredValues.reduce(0, +) / Double(filteredValues.count)
        let sumSquaredDiff = filteredValues.map { pow($0 - mean, 2.0) }.reduce(0, +)
        let sd = sqrt(sumSquaredDiff / Double(filteredValues.count))
        
        // 3. Calculate Trend (Simple linear regression slope on the last 14 days)
        let trendValues = Array(values.suffix(14))
        let slope = calculateSlope(trendValues)
        let trend = Baseline.TrendDirection.trend(for: metric, slope: slope)
        
        // 4. Create and Save Baseline
        let baseline = Baseline(
            userId: userId,
            metric: metric,
            mean: mean,
            standardDeviation: sd,
            startDate: dates.first ?? Date(),
            endDate: dates.last ?? Date(),
            sampleCount: filteredValues.count,
            windowDays: windowDays,
            trend: trend,
            trendSlope: slope
        )
        
        try await repo.saveBaseline(baseline)
    }
    
    private func filterOutliers(_ values: [Double]) -> [Double] {
        guard values.count > 4 else { return values }
        
        let sorted = values.sorted()
        let q1 = sorted[Int(Double(sorted.count) * 0.25)]
        let q3 = sorted[Int(Double(sorted.count) * 0.75)]
        let iqr = q3 - q1
        
        let lowerBound = q1 - (1.5 * iqr)
        let upperBound = q3 + (1.5 * iqr)
        
        return values.filter { $0 >= lowerBound && $0 <= upperBound }
    }
    
    private func calculateSlope(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0.0 }
        
        // Simple slope: (end - start) / start / days
        // A more robust way would be least squares regression
        let first = values.first!
        let last = values.last!
        
        guard first > 0 else { return 0.0 }
        
        return (last - first) / first / Double(values.count)
    }
}
