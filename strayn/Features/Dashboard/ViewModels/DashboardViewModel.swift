//
//  DashboardViewModel.swift
//  strayn
//

import Foundation
import Combine
import HealthKit

@MainActor
class DashboardViewModel: ObservableObject {
    // Published State
    @Published var recovery: DailyRecovery?
    @Published var strain: DailyStrain?
    @Published var sleep: SleepSession?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var healthBrief: HealthBrief?
    @Published var sleepDetection = SleepDetectionService.shared
    
    // Repositories
    private let recoveryRepo: RecoveryRepositoryProtocol
    private let strainRepo: StrainRepositoryProtocol
    private let sleepRepo: SleepRepositoryProtocol
    private let healthKitService: HealthKitService
    
    init(
        recoveryRepo: RecoveryRepositoryProtocol = CoreDataRecoveryRepository.shared,
        strainRepo: StrainRepositoryProtocol = CoreDataStrainRepository.shared,
        sleepRepo: SleepRepositoryProtocol = CoreDataSleepRepository.shared,
        healthKitService: HealthKitService = .shared
    ) {
        self.recoveryRepo = recoveryRepo
        self.strainRepo = strainRepo
        self.sleepRepo = sleepRepo
        self.healthKitService = healthKitService
    }
    
    func refreshData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let today = Date()
            
            // Fetch current data
            let rec = try await recoveryRepo.getRecovery(for: today)
            let str = try await strainRepo.getStrain(for: today)
            let slp = try await sleepRepo.getSleep(for: today)
            
            // If DB is completely empty (first run), populate with mock data for better UX
            if rec == nil && str == nil && slp == nil {
                print("Database empty, populating mock data...")
                await MockDataService.shared.populateAllMockData()
                
                // Re-fetch
                self.recovery = try await recoveryRepo.getRecovery(for: today)
                self.strain = try await strainRepo.getStrain(for: today)
                self.sleep = try await sleepRepo.getSleep(for: today)
            } else {
                self.recovery = rec
                self.strain = str
                self.sleep = slp
            }
            
            // Generate Daily Brief
            self.healthBrief = InsightEngine.shared.generateDailyBrief(recovery: self.recovery, strain: self.strain, sleep: self.sleep)
            
        } catch {
            self.errorMessage = "Failed to load dashboard data"
            print("Dashboard load error: \(error)")
        }
        
        isLoading = false
    }
    
    func requestPermissions() async {
        // Only request if not in simulator or if testing real HK
        #if !targetEnvironment(simulator)
        do {
            try await healthKitService.requestEssentialAuthorization()
            await refreshData()
        } catch {
            self.errorMessage = "Health permissions denied"
        }
        #else
        // In simulator, prioritize mock data
        await refreshData()
        #endif
    }
}
