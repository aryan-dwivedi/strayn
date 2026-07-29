//
//  HealthspanEngine.swift
//  strayn
//
//  Main orchestrator for the Healthspan feature. Coordinates calculation
//  of Strayn Age, Pace of Aging, and generates insights.
//

import Foundation

// MARK: - Healthspan Engine Protocol

protocol HealthspanEngineProtocol {
    func calculateHealthspan(for user: User, recoveries: [DailyRecovery], strains: [DailyStrain], sleepSessions: [SleepSession], baselines: [Baseline]) async throws -> Healthspan
    func checkUnlockEligibility(validDaysCount: Int, windowDays: Int) -> HealthspanState
    func calculateCalibrationProgress(totalValidDays: Int) -> Double
    func shouldUpdate(lastUpdated: Date) -> Bool
}

// MARK: - Healthspan Engine

final class HealthspanEngine: HealthspanEngineProtocol {
    
    // MARK: - Shared Instance
    
    static let shared = HealthspanEngine()
    
    // MARK: - Dependencies
    
    private let straynAgeEngine: StraynAgeCalculationEngine
    private let paceOfAgingEngine: PaceOfAgingEngine
    private let insightEngine: HealthspanInsightEngine
    
    // MARK: - Configuration
    
    private let requirements = HealthspanUnlockRequirements.self
    
    // MARK: - Initialization
    
    init(
        straynAgeEngine: StraynAgeCalculationEngine = .shared,
        paceOfAgingEngine: PaceOfAgingEngine = .shared,
        insightEngine: HealthspanInsightEngine = .shared
    ) {
        self.straynAgeEngine = straynAgeEngine
        self.paceOfAgingEngine = paceOfAgingEngine
        self.insightEngine = insightEngine
    }
    
    // MARK: - Main Calculation
    
    func calculateHealthspan(
        for user: User,
        recoveries: [DailyRecovery],
        strains: [DailyStrain],
        sleepSessions: [SleepSession],
        baselines: [Baseline]
    ) async throws -> Healthspan {
        
        let now = Date()
        let calendar = Calendar.current
        
        // 1. Calculate data windows
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now) ?? now
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let thirtyOneDaysAgo = calendar.date(byAdding: .day, value: -31, to: now) ?? now
        
        // 2. Filter data to relevant windows
        let recoveries6Month = recoveries.filter { $0.date >= sixMonthsAgo }
        let recoveries30Day = recoveries.filter { $0.date >= thirtyDaysAgo }
        let strains6Month = strains.filter { $0.date >= sixMonthsAgo }
        let sleepSessions6Month = sleepSessions.filter { $0.date >= sixMonthsAgo }
        let sleepSessions30Day = sleepSessions.filter { $0.date >= thirtyDaysAgo }
        
        // 3. Count valid days (days with sufficient data)
        let validDaysLast31 = countValidDays(
            recoveries: recoveries.filter { $0.date >= thirtyOneDaysAgo },
            strains: strains.filter { $0.date >= thirtyOneDaysAgo },
            sleepSessions: sleepSessions.filter { $0.date >= thirtyOneDaysAgo }
        )
        
        let totalValidDays = countValidDays(
            recoveries: recoveries6Month,
            strains: strains6Month,
            sleepSessions: sleepSessions6Month
        )
        
        // 4. Check state
        let state = checkUnlockEligibility(validDaysCount: validDaysLast31, windowDays: 31)
        let calibrationProgress = calculateCalibrationProgress(totalValidDays: totalValidDays)
        
        // 5. Build input data for Strayn Age
        let straynAgeInput = buildStraynAgeInputData(
            user: user,
            recoveries: recoveries6Month,
            strains: strains6Month,
            sleepSessions: sleepSessions6Month,
            baselines: baselines
        )
        
        // 6. Calculate Strayn Age
        let straynAge = straynAgeEngine.calculateStraynAge(
            input: straynAgeInput,
            previousStraynAge: nil  // TODO: Load from persistence
        )
        
        // 7. Build input data for Pace of Aging
        let paceInput = buildPaceOfAgingInputData(
            recoveries30Day: recoveries30Day,
            strains30Day: strains.filter { $0.date >= thirtyDaysAgo },
            sleepSessions30Day: sleepSessions30Day,
            baselines: baselines,
            previousPace: nil  // TODO: Load from persistence
        )
        
        // 8. Calculate Pace of Aging
        let paceOfAging = paceOfAgingEngine.calculatePaceOfAging(input: paceInput)
        
        // 9. Calculate data quality
        let dataQuality = calculateDataQuality(
            recoveries: recoveries6Month,
            strains: strains6Month,
            sleepSessions: sleepSessions6Month,
            totalDays: 180
        )
        
        // 10. Calculate next update date
        let nextUpdate = calendar.date(byAdding: .day, value: requirements.updateFrequencyDays, to: now) ?? now
        
        // 11. Build final Healthspan object
        return Healthspan(
            userId: user.id,
            straynAge: straynAge,
            paceOfAging: paceOfAging,
            state: state,
            calibrationProgress: calibrationProgress,
            windowStart: sixMonthsAgo,
            windowEnd: now,
            validDaysInWindow: totalValidDays,
            lastUpdated: now,
            nextUpdateDate: nextUpdate,
            dataQuality: dataQuality,
            dataCompleteness: Double(totalValidDays) / 180.0
        )
    }
    
    // MARK: - State Management
    
    func checkUnlockEligibility(validDaysCount: Int, windowDays: Int) -> HealthspanState {
        let minRequired = requirements.minimumValidDaysToUnlock
        
        if validDaysCount < minRequired {
            return .locked(reason: .insufficientData)
        }
        
        // Check calibration phase
        if validDaysCount < requirements.partialCalibrationDays {
            return .calibrating(phase: .partial(
                daysCompleted: validDaysCount,
                daysRequired: requirements.partialCalibrationDays
            ))
        }
        
        if validDaysCount < requirements.fullCalibrationDays {
            return .calibrating(phase: .full(
                daysCompleted: validDaysCount,
                daysRequired: requirements.fullCalibrationDays
            ))
        }
        
        return .active
    }
    
    func calculateCalibrationProgress(totalValidDays: Int) -> Double {
        let fullCalibration = Double(requirements.fullCalibrationDays)
        return min(1.0, Double(totalValidDays) / fullCalibration)
    }
    
    func shouldUpdate(lastUpdated: Date) -> Bool {
        let daysSinceUpdate = Calendar.current.dateComponents(
            [.day],
            from: lastUpdated,
            to: Date()
        ).day ?? 0
        return daysSinceUpdate >= requirements.updateFrequencyDays
    }
    
    // MARK: - Private Helpers
    
    private func countValidDays(
        recoveries: [DailyRecovery],
        strains: [DailyStrain],
        sleepSessions: [SleepSession]
    ) -> Int {
        // A valid day has either recovery data OR sleep data
        var validDates = Set<String>()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for recovery in recoveries where !recovery.hasInsufficientData {
            validDates.insert(formatter.string(from: recovery.date))
        }
        
        for sleep in sleepSessions where sleep.totalDuration > 3600 {  // At least 1 hour
            validDates.insert(formatter.string(from: sleep.date))
        }
        
        return validDates.count
    }
    
    private func buildStraynAgeInputData(
        user: User,
        recoveries: [DailyRecovery],
        strains: [DailyStrain],
        sleepSessions: [SleepSession],
        baselines: [Baseline]
    ) -> StraynAgeInputData {
        
        // Sleep metrics
        let avgSleepDuration = sleepSessions.isEmpty ? nil :
            sleepSessions.map { $0.totalDuration }.reduce(0, +) / Double(sleepSessions.count)
        
        let sleepConsistency = calculateSleepConsistency(sleepSessions: sleepSessions)
        
        let avgDeepSleep = sleepSessions.compactMap { $0.deepSleepDuration }
            .isEmpty ? nil : sleepSessions.compactMap { $0.deepSleepDuration }
            .reduce(0, +) / Double(sleepSessions.compactMap { $0.deepSleepDuration }.count)
        
        let avgREMSleep = sleepSessions.compactMap { $0.remSleepDuration }
            .isEmpty ? nil : sleepSessions.compactMap { $0.remSleepDuration }
            .reduce(0, +) / Double(sleepSessions.compactMap { $0.remSleepDuration }.count)
        
        let avgEfficiency = sleepSessions.isEmpty ? nil :
            sleepSessions.map { $0.sleepEfficiency }.reduce(0, +) / Double(sleepSessions.count)
        
        // Activity metrics
        let weeklyModerate = calculateWeeklyZoneMinutes(strains: strains, zones: [1, 2, 3])
        let weeklyHighIntensity = calculateWeeklyZoneMinutes(strains: strains, zones: [4, 5])
        let avgSteps = calculateAverageDailySteps(strains: strains)
        
        // Cardiovascular metrics
        let avgRHR = recoveries.compactMap { $0.rawRestingHR }.isEmpty ? nil :
            recoveries.compactMap { $0.rawRestingHR }.reduce(0, +) / Double(recoveries.compactMap { $0.rawRestingHR }.count)
        
        let avgVO2Max = recoveries.compactMap { $0.rawVO2Max }.isEmpty ? nil :
            recoveries.compactMap { $0.rawVO2Max }.reduce(0, +) / Double(recoveries.compactMap { $0.rawVO2Max }.count)
        
        // Recovery metrics
        let avgHRV = recoveries.compactMap { $0.rawHRV }.isEmpty ? nil :
            recoveries.compactMap { $0.rawHRV }.reduce(0, +) / Double(recoveries.compactMap { $0.rawHRV }.count)
        
        let avgRecoveryScore = recoveries.isEmpty ? nil :
            recoveries.map { $0.recoveryScore }.reduce(0, +) / Double(recoveries.count)
        
        // Find trends from baselines
        let rhrTrend = baselines.first { $0.metric == .restingHR }?.trend
        let hrvTrend = baselines.first { $0.metric == .hrv }?.trend
        
        return StraynAgeInputData(
            averageSleepDuration: avgSleepDuration,
            sleepConsistencyScore: sleepConsistency,
            deepSleepPercentage: avgDeepSleep.map { avgSleepDuration != nil ? $0 / avgSleepDuration! : nil } ?? nil,
            remSleepPercentage: avgREMSleep.map { avgSleepDuration != nil ? $0 / avgSleepDuration! : nil } ?? nil,
            sleepEfficiencyAverage: avgEfficiency,
            weeklyModerateAerobicMinutes: weeklyModerate,
            weeklyHighIntensityMinutes: weeklyHighIntensity,
            weeklyStrengthTrainingMinutes: nil,  // TODO: Extract from workout types
            dailyStepAverage: avgSteps,
            stepConsistencyScore: nil,
            restingHeartRateAverage: avgRHR,
            restingHeartRateTrend: rhrTrend,
            vo2Max: avgVO2Max,
            vo2MaxTrend: nil,
            cardiacEfficiencyScore: nil,
            hrvAverage: avgHRV,
            hrvTrend: hrvTrend,
            averageRecoveryScore: avgRecoveryScore,
            recoveryConsistency: nil,
            chronologicalAge: user.age,
            biologicalSex: user.biologicalSex,
            height: nil,
            weight: nil,
            leanBodyMass: nil,
            daysWithSleepData: sleepSessions.count,
            daysWithActivityData: strains.count,
            daysWithHeartRateData: recoveries.filter { $0.rawRestingHR != nil }.count,
            totalDaysInWindow: 180
        )
    }
    
    private func buildPaceOfAgingInputData(
        recoveries30Day: [DailyRecovery],
        strains30Day: [DailyStrain],
        sleepSessions30Day: [SleepSession],
        baselines: [Baseline],
        previousPace: Double?
    ) -> PaceOfAgingInputData {
        
        // Recent metrics (30-day)
        let recentSleepDuration = sleepSessions30Day.isEmpty ? nil :
            sleepSessions30Day.map { $0.totalDuration }.reduce(0, +) / Double(sleepSessions30Day.count)
        
        let recentSleepConsistency = calculateSleepConsistency(sleepSessions: sleepSessions30Day)
        
        let recentRHR = recoveries30Day.compactMap { $0.rawRestingHR }.isEmpty ? nil :
            recoveries30Day.compactMap { $0.rawRestingHR }.reduce(0, +) / Double(recoveries30Day.compactMap { $0.rawRestingHR }.count)
        
        let recentHRV = recoveries30Day.compactMap { $0.rawHRV }.isEmpty ? nil :
            recoveries30Day.compactMap { $0.rawHRV }.reduce(0, +) / Double(recoveries30Day.compactMap { $0.rawHRV }.count)
        
        let recentRecovery = recoveries30Day.isEmpty ? nil :
            recoveries30Day.map { $0.recoveryScore }.reduce(0, +) / Double(recoveries30Day.count)
        
        // Baseline metrics from stored baselines
        let baselineSleepDuration = baselines.first { $0.metric == .sleepDuration }?.mean // Already in correct units
        let baselineRHR = baselines.first { $0.metric == .restingHR }?.mean
        let baselineHRV = baselines.first { $0.metric == .hrv }?.mean
        
        return PaceOfAgingInputData(
            recentSleepDuration: recentSleepDuration,
            recentSleepConsistency: recentSleepConsistency,
            recentDeepSleepPercentage: nil,
            recentWeeklyActivityMinutes: calculateWeeklyZoneMinutes(strains: strains30Day, zones: [1, 2, 3, 4, 5]),
            recentDailySteps: calculateAverageDailySteps(strains: strains30Day),
            recentStrengthMinutes: nil,
            recentRestingHR: recentRHR,
            recentVO2Max: recoveries30Day.compactMap { $0.rawVO2Max }.last,
            recentHRV: recentHRV,
            recentRecoveryScore: recentRecovery,
            baselineSleepDuration: baselineSleepDuration,
            baselineSleepConsistency: nil,
            baselineDeepSleepPercentage: nil,
            baselineWeeklyActivityMinutes: nil,
            baselineDailySteps: nil,
            baselineStrengthMinutes: nil,
            baselineRestingHR: baselineRHR,
            baselineVO2Max: nil,
            baselineHRV: baselineHRV,
            baselineRecoveryScore: nil,
            previousPace: previousPace,
            recentDaysWithData: recoveries30Day.count,
            baselineDaysWithData: 150  // Approximate
        )
    }
    
    private func calculateSleepConsistency(sleepSessions: [SleepSession]) -> Double? {
        guard sleepSessions.count >= 7 else { return nil }
        
        let calendar = Calendar.current
        let bedtimes = sleepSessions.map { session -> Double in
            let components = calendar.dateComponents([.hour, .minute], from: session.startDate)
            var hours = Double(components.hour ?? 0)
            if hours < 12 { hours += 24 }  // Handle after-midnight bedtimes
            return hours + Double(components.minute ?? 0) / 60.0
        }
        
        let waketimes = sleepSessions.map { session -> Double in
            let components = calendar.dateComponents([.hour, .minute], from: session.endDate)
            return Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60.0
        }
        
        let bedtimeVariance = calculateVariance(values: bedtimes)
        let waketimeVariance = calculateVariance(values: waketimes)
        
        // Lower variance = higher consistency score
        // Score of 100 = perfectly consistent, Score of 0 = highly variable
        let maxVariance = 4.0  // 2-hour standard deviation considered very bad
        let avgVariance = (bedtimeVariance + waketimeVariance) / 2.0
        let consistencyScore = max(0, 100 - (avgVariance / maxVariance * 100))
        
        return consistencyScore
    }
    
    private func calculateVariance(values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        return squaredDiffs.reduce(0, +) / Double(values.count)
    }
    
    private func calculateWeeklyZoneMinutes(strains: [DailyStrain], zones: [Int]) -> Double? {
        guard !strains.isEmpty else { return nil }
        
        let totalSeconds = strains.reduce(0.0) { total, strain in
            var zoneTime: TimeInterval = 0
            for zone in zones {
                zoneTime += strain.time(in: zone)
            }
            return total + zoneTime
        }
        
        // Convert to weekly average in minutes
        let days = max(1, strains.count)
        let dailyAverage = totalSeconds / Double(days)
        let weeklyAverage = dailyAverage * 7 / 60.0  // Convert to minutes
        
        return weeklyAverage
    }
    
    private func calculateAverageDailySteps(strains: [DailyStrain]) -> Double? {
        // Note: Steps would typically come from HealthKit, using strain as proxy
        // This is a placeholder - in real implementation, query HKQuantityType.stepCount
        return nil
    }
    
    private func calculateDataQuality(
        recoveries: [DailyRecovery],
        strains: [DailyStrain],
        sleepSessions: [SleepSession],
        totalDays: Int
    ) -> Healthspan.DataQuality {
        
        let sleepQuality = min(1.0, Double(sleepSessions.count) / Double(totalDays))
        let activityQuality = min(1.0, Double(strains.count) / Double(totalDays))
        let heartRateQuality = min(1.0, Double(recoveries.filter { $0.rawRestingHR != nil }.count) / Double(totalDays))
        
        let overallScore = (sleepQuality + activityQuality + heartRateQuality) / 3.0
        
        let overallLevel: Healthspan.DataQuality.QualityLevel
        switch overallScore {
        case 0.8...: overallLevel = .excellent
        case 0.6..<0.8: overallLevel = .good
        case 0.4..<0.6: overallLevel = .fair
        default: overallLevel = .poor
        }
        
        return Healthspan.DataQuality(
            sleepDataQuality: sleepQuality,
            activityDataQuality: activityQuality,
            heartRateDataQuality: heartRateQuality,
            overallQuality: overallLevel
        )
    }
}

// MARK: - Mock Data Support

extension HealthspanEngine {
    
    /// Creates a mock Healthspan for testing and previews
    static func createMockHealthspan(
        chronologicalAge: Int = 35,
        straynAgeDelta: Double = -1.2,
        paceOfAging: Double = 0.3,
        state: HealthspanState = .active
    ) -> Healthspan {
        let now = Date()
        let calendar = Calendar.current
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now)!
        
        let straynAge = StraynAgeCalculationEngine.createMockStraynAge(
            chronologicalAge: chronologicalAge,
            ageDelta: straynAgeDelta
        )
        
        let pace = PaceOfAgingEngine.createMockPaceOfAging(pace: paceOfAging)
        
        return Healthspan(
            userId: UUID(),
            straynAge: straynAge,
            paceOfAging: pace,
            state: state,
            calibrationProgress: state == .active ? 1.0 : 0.7,
            windowStart: sixMonthsAgo,
            windowEnd: now,
            validDaysInWindow: 150,
            nextUpdateDate: calendar.date(byAdding: .day, value: 3, to: now)!,
            dataQuality: Healthspan.DataQuality(
                sleepDataQuality: 0.85,
                activityDataQuality: 0.78,
                heartRateDataQuality: 0.92,
                overallQuality: .good
            ),
            dataCompleteness: 0.83
        )
    }
}
