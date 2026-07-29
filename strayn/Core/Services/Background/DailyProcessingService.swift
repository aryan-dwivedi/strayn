//
//  DailyProcessingService.swift
//  strayn
//
//  Orchestrates metric calculation and data persistence
//

import Foundation
import HealthKit
import Combine

class DailyProcessingService {
    static let shared = DailyProcessingService()
    
    private let healthKitService = HealthKitService.shared
    private let recoveryRepo = CoreDataRecoveryRepository.shared
    private let strainRepo = CoreDataStrainRepository.shared
    private let sleepRepo = CoreDataSleepRepository.shared
    private let baselineRepo = CoreDataBaselineRepository.shared
    private let userRepo = CoreDataUserRepository.shared
    
    private init() {}
    
    /// Main entry point for processing today's metrics
    /// Typically called in background or on app launch
    func processDailyMetrics() async throws {
        guard let user = try await userRepo.getCurrentUser() else {
            print("No user profile found, skipping processing.")
            return
        }
        
        let today = Date()
        
        // 1. Fetch Sleep & Calculate Performance
        let sleepSamples = try await healthKitService.fetchSleepAnalysis(for: today)
        if let lastSample = sleepSamples.last {
            let session = SleepSession(
                date: today,
                startDate: sleepSamples.first?.startDate ?? today,
                endDate: lastSample.endDate,
                totalDuration: sleepSamples.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) },
                inBedDuration: lastSample.endDate.timeIntervalSince(sleepSamples.first?.startDate ?? today),
                sleepEfficiency: 0.9, // Placeholder
                sleepNeed: user.sleepNeedHours * 3600
            )
            try await sleepRepo.saveSleepSession(session)
        }
        
        // 2. Update Baselines (if we have enough data)
        try await BaselineService.shared.updateAllBaselines(
            userId: user.id,
            recoveryRepo: recoveryRepo,
            sleepRepo: sleepRepo,
            baselineRepo: baselineRepo
        )
        
        // 3. Calculate Recovery Score
        let hrv = try await healthKitService.fetchOvernightHRV(for: today)
        let rhr = try await healthKitService.fetchRestingHeartRate(for: today)
        let rr = try await healthKitService.fetchRespiratoryRate(for: today)
        let vo2 = try await healthKitService.fetchVO2Max(for: today)
        let sleepSession = try await sleepRepo.getSleep(for: today)
        
        let hrvBaseline = try await baselineRepo.getBaseline(for: .hrv, userId: user.id)
        let rhrBaseline = try await baselineRepo.getBaseline(for: .restingHR, userId: user.id)
        
        // Preserve existing journal data
        let existingRecovery = try await recoveryRepo.getRecovery(for: today)
        
        // ... (Previous baselines fetching)
        
        // New Physiological Engine Calculations
        let currentHRV = hrv ?? hrvBaseline?.mean ?? 50.0
        let currentRHR = rhr ?? rhrBaseline?.mean ?? 60.0
        
        let balance = PhysiologyService.shared.calculateAutonomicBalance(
            currentHRV: currentHRV, 
            baselineHRV: hrvBaseline?.mean ?? currentHRV
        )
        
        let stress = PhysiologyService.shared.calculateStressLoad(
            restingHR: currentRHR, 
            baselineRHR: rhrBaseline?.mean ?? currentRHR, 
            hrv: currentHRV, 
            baselineHRV: hrvBaseline?.mean ?? currentHRV
        )
        
        // Calculate Strayn Age
        let age = StraynAgeEngine.shared.calculateStraynAge(
            chronologicalAge: user.age,
            rhr: currentRHR,
            hrv: currentHRV,
            sleepEfficiency: sleepSession?.sleepEfficiency ?? 0.9,
            vo2Max: vo2
        )
        
        // Recalculate Score with Advanced Metrics
        var recovery = RecoveryScoreCalculator.shared.calculateRecovery(
            date: today,
            hrv: hrv,
            rhr: rhr,
            sleepDuration: sleepSession?.totalDuration,
            respiratoryRate: rr,
            hrvBaseline: hrvBaseline,
            rhrBaseline: rhrBaseline,
            sleepTarget: user.sleepNeedHours * 3600
        )
        
        // Inject Derived Metrics
        recovery = DailyRecovery(
            id: recovery.id,
            date: recovery.date,
            recoveryScore: recovery.recoveryScore,
            recoveryZone: recovery.recoveryZone,
            hrvScore: recovery.hrvScore,
            restingHRScore: recovery.restingHRScore,
            sleepScore: recovery.sleepScore,
            respiratoryRateScore: recovery.respiratoryRateScore,
            rawHRV: recovery.rawHRV,
            rawRestingHR: recovery.rawRestingHR,
            rawSleepDuration: recovery.rawSleepDuration,
            rawRespiratoryRate: recovery.rawRespiratoryRate,
            hrvBaseline: hrvBaseline?.mean ?? 0,
            restingHRBaseline: rhrBaseline?.mean ?? 0,
            autonomicBalance: balance,
            stressLoad: stress,
            cardiacEfficiency: recovery.cardiacEfficiency,
            recoveryContributors: recovery.recoveryContributors,
            straynAge: age,
            rawVO2Max: vo2,
            calculatedAt: recovery.calculatedAt,
            hasInsufficientData: recovery.hasInsufficientData,
            dataQualityScore: recovery.dataQualityScore,
            journalData: existingRecovery?.journalData
        )
        
        try await recoveryRepo.saveRecovery(recovery)
        
        // 4. Calculate Strain Score
        let hrSamples = try await healthKitService.fetchHeartRateSamples(for: today)
        let workouts = try await healthKitService.fetchWorkouts(for: today)
        
        let strain = StrainScoreCalculator.shared.calculateStrain(
            date: today,
            heartRateSamples: hrSamples,
            maxHR: user.maxHeartRate ?? user.estimatedMaxHeartRate(),
            workouts: workouts
        )
        try await strainRepo.saveStrain(strain)
        
        print("Daily processing completed for \(today)")
    }
}
