//
//  MorningJournalViewModel.swift
//  strayn
//
//  ViewModel for Morning Journal feature
//

import Foundation
import SwiftUI
import Combine
@MainActor
class MorningJournalViewModel: ObservableObject {

    @Published var alcohol: String = "None"
    @Published var caffeine: String = "None"
    @Published var screenInBed: Bool = false
    @Published var lateMeal: Bool = false
    @Published var isSubmitting = false
    @Published var submissionSuccess = false
    
    private let repository: RecoveryRepositoryProtocol
    private let habitService = HabitTrackerService.shared
    
    init(repository: RecoveryRepositoryProtocol = CoreDataRecoveryRepository.shared) {
        self.repository = repository
        
        // Try to load existing journal if any
        Task {
            await loadExistingJournal()
        }
    }
    
    private func loadExistingJournal() async {
        let today = Date()
        guard let recovery = try? await repository.getRecovery(for: today),
              let jsonString = recovery.journalData,
              let data = jsonString.data(using: .utf8),
              let journal = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        // Populate fields
        self.alcohol = journal["alcohol"] as? String ?? "None"
        self.caffeine = journal["caffeine"] as? String ?? "None"
        self.screenInBed = (journal["screenInBed"] as? String) == "true"
        self.lateMeal = (journal["lateMeal"] as? String) == "true"
    }
    
    func saveJournal() async {
        isSubmitting = true
        
        let journalDict: [String: Any] = [
            "alcohol": alcohol,
            "caffeine": caffeine,
            "screenInBed": String(screenInBed),
            "lateMeal": String(lateMeal)
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: journalDict),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            isSubmitting = false
            return
        }
        
        do {
            let today = Date()
            
            // Log structured habits for correlation engine
            try? await habitService.logHabit(id: "alcohol", value: alcohol)
            try? await habitService.logHabit(id: "caffeine", value: caffeine)
            try? await habitService.logHabit(id: "screen_in_bed", value: String(screenInBed))
            try? await habitService.logHabit(id: "late_meal", value: String(lateMeal))
            
            if let existingRecovery = try await repository.getRecovery(for: today) {
                let updatedRecovery = DailyRecovery(
                    id: existingRecovery.id,
                    date: existingRecovery.date,
                    recoveryScore: existingRecovery.recoveryScore,
                    recoveryZone: existingRecovery.recoveryZone,
                    hrvScore: existingRecovery.hrvScore,
                    restingHRScore: existingRecovery.restingHRScore,
                    sleepScore: existingRecovery.sleepScore,
                    respiratoryRateScore: existingRecovery.respiratoryRateScore,
                    rawHRV: existingRecovery.rawHRV,
                    rawRestingHR: existingRecovery.rawRestingHR,
                    rawSleepDuration: existingRecovery.rawSleepDuration,
                    rawRespiratoryRate: existingRecovery.rawRespiratoryRate,
                    hrvBaseline: existingRecovery.hrvBaseline,
                    restingHRBaseline: existingRecovery.restingHRBaseline,
                    autonomicBalance: existingRecovery.autonomicBalance,
                    stressLoad: existingRecovery.stressLoad,
                    cardiacEfficiency: existingRecovery.cardiacEfficiency,
                    recoveryContributors: existingRecovery.recoveryContributors,
                    straynAge: existingRecovery.straynAge,
                    calculatedAt: existingRecovery.calculatedAt,
                    hasInsufficientData: existingRecovery.hasInsufficientData,
                    dataQualityScore: existingRecovery.dataQualityScore,
                    journalData: jsonString
                )
                try await repository.saveRecovery(updatedRecovery)
                submissionSuccess = true
            } else {
                let dummyRecovery = DailyRecovery(
                    date: today,
                    recoveryScore: 0,
                    recoveryZone: .red,
                    hrvScore: 0,
                    restingHRScore: 0,
                    sleepScore: 0,
                    respiratoryRateScore: 0,
                    journalData: jsonString
                )
                try await repository.saveRecovery(dummyRecovery)
                submissionSuccess = true
            }
        } catch {
            print("Error saving journal: \(error)")
        }
        
        isSubmitting = false
    }
}
