//
//  SleepDetectionService.swift
//  strayn
//
//  Created by Aryan Dwivedi on 18/01/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SleepDetectionService: ObservableObject {
    static let shared = SleepDetectionService()
    
    @Published var detectedSleepSession: SleepSession?
    @Published var showSleepPrompt = false
    
    private init() {}
    
    func simulateSleepDetection() {
        // In a real app, this would be triggered by a background task or push notification
        // finding a new sleep sample in HealthKit.
        
        let start = Calendar.current.date(byAdding: .hour, value: -8, to: Date())!
        let end = Date()
        
        let session = SleepSession(
            date: Date(),
            startDate: start,
            endDate: end,
            totalDuration: 7.5 * 3600,
            inBedDuration: 8.0 * 3600,
            sleepEfficiency: 0.94,
            sleepNeed: 8.0 * 3600
        )
        
        self.detectedSleepSession = session
        self.showSleepPrompt = true
        HapticsManager.shared.playNotification(.success)
    }
    
    func confirmSleep() async {
        guard let session = detectedSleepSession else { return }
        do {
            try await CoreDataSleepRepository.shared.saveSleepSession(session)
            // Trigger processing
            try await DailyProcessingService.shared.processDailyMetrics()
            showSleepPrompt = false
        } catch {
            print("Failed to save confirmed sleep")
        }
    }
}
