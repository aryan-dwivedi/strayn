//
//  MockDataService.swift
//  strayn
//
//  Generates realistic synthetic data for testing and development.
//

import Foundation
import CoreData

class MockDataService {
    static let shared = MockDataService()
    
    private let recoveryRepo = CoreDataRecoveryRepository.shared
    private let strainRepo = CoreDataStrainRepository.shared
    private let sleepRepo = CoreDataSleepRepository.shared
    private let userRepo = CoreDataUserRepository.shared
    
    private init() {}
    
    /// Populates the database with 30 days of mock data
    func populateAllMockData() async {
        guard let user = try? await userRepo.getCurrentUser() else {
            // Create a default user if none exists
            let newUser = User(
                id: UUID(),
                age: 30,
                biologicalSex: .male,
                maxHeartRate: 190,
                sleepNeedHours: 8.0
            )
            try? await userRepo.saveUser(newUser)
            await populateAllMockData()
            return
        }
        
        // Check if data already exists to avoid duplication purely for this mock logic
        // For development speed we might want to nuke and recreate, but let's be additive for now or just check today.
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        print("Starting mock data population...")
        
        for daysAgo in (0...30).reversed() {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            
            // 1. Generate Sleep
            let isWeekend = calendar.isDateInWeekend(date)
            // Fluctuate sleep debt
            let sleepDebtPixels = sin(Double(daysAgo) * 0.5) * 3600 // Cyclic debt
            
            let sleepDuration = Double.random(in: 6...8.5) * 3600 + (isWeekend ? 3600 : 0) - (sleepDebtPixels * 0.1)
            let sleep = SleepSession(
                date: date,
                startDate: calendar.date(byAdding: .hour, value: -8, to: date)!,
                endDate: date,
                totalDuration: sleepDuration,
                inBedDuration: sleepDuration + 1800,
                sleepEfficiency: Double.random(in: 0.85...0.98),
                sleepNeed: 8.0 * 3600
            )
            try? await sleepRepo.saveSleepSession(sleep)
            
            // 2. Generate Recovery
            // Correlate recovery with sleep: Better sleep -> better recovery
            let sleepFactor = (sleepDuration / (8.0 * 3600)) * 50
            let randomVar = Double.random(in: -10...10)
            let baseScore = 40.0 + sleepFactor + randomVar
            let score = min(max(baseScore, 10.0), 99.0) // Clamp 10-99
            
            let hrv = Double.random(in: 40...110) + (score * 0.2)
            let rhr = Double.random(in: 45...65) - (score * 0.1)
            
            let recovery = DailyRecovery(
                date: date,
                recoveryScore: score,
                recoveryZone: DailyRecovery.RecoveryZone.zone(for: score),
                hrvScore: hrv, 
                restingHRScore: rhr,
                sleepScore: (sleepDuration / (8 * 3600)) * 100,
                respiratoryRateScore: 50,
                rawHRV: hrv,
                rawRestingHR: rhr,
                rawSleepDuration: sleepDuration,
                rawRespiratoryRate: Double.random(in: 13...15.5),
                hrvBaseline: 65.0,
                restingHRBaseline: 55.0,
                autonomicBalance: Double.random(in: 0.4...0.7) + (score > 66 ? 0.2 : 0),
                stressLoad: Double.random(in: 10...50) + (100 - score) * 0.3,
                recoveryContributors: [
                    "Sleep": sleepFactor > 40 ? 15 : -10,
                    "HRV": hrv > 60 ? 10 : -5
                ],
                straynAge: Double(user.age) - (score > 66 ? 2.5 : -1.0),
                rawVO2Max: Double.random(in: 42...48)
            )
            try? await recoveryRepo.saveRecovery(recovery)
            
            // 3. Generate Strain
            let strainScore = isWeekend ? Double.random(in: 14...18) : Double.random(in: 8...13)
            let strain = DailyStrain(
                date: date,
                strainScore: strainScore,
                timeInZone1: 1000.0,
                timeInZone2: 2000.0,
                timeInZone3: 1500.0,
                timeInZone4: 500.0,
                timeInZone5: 100.0,
                workoutStrain: strainScore * 0.7,
                dailyActivityStrain: strainScore * 0.3
            )
            try? await strainRepo.saveStrain(strain)
        }
        
        print("Mock data population complete.")
    }
}
