//
//  BackgroundTaskService.swift
//  strayn
//
//  Handles registration and scheduling of background tasks
//

import Foundation
import BackgroundTasks
import Combine

class BackgroundTaskService {
    static let shared = BackgroundTaskService()
    
    let dailyRecoveryTaskId = "com.strayn.dailyRecoveryCalculation"
    
    private init() {}
    
    /// Register all background tasks. Call this on app launch.
    func registerTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: dailyRecoveryTaskId, using: nil) { task in
            self.handleDailyRecoveryTask(task: task as! BGAppRefreshTask)
        }
    }
    
    /// Schedule the next daily recovery calculation
    func scheduleDailyRecovery() {
        let request = BGAppRefreshTaskRequest(identifier: dailyRecoveryTaskId)
        
        // Schedule for 7:00 AM tomorrow
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = 7
        dateComponents.minute = 0
        
        if let nextExecution = Calendar.current.date(from: dateComponents), nextExecution < Date() {
            request.earliestBeginDate = Calendar.current.date(byAdding: .day, value: 1, to: nextExecution)
        } else {
            request.earliestBeginDate = Calendar.current.date(from: dateComponents)
        }
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled background task: \(dailyRecoveryTaskId) for \(String(describing: request.earliestBeginDate))")
        } catch {
            print("Could not schedule background task: \(error)")
        }
    }
    
    private func handleDailyRecoveryTask(task: BGAppRefreshTask) {
        // Reschedule for the next day
        scheduleDailyRecovery()
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        task.expirationHandler = {
            queue.cancelAllOperations()
        }
        
        Task {
            do {
                // Execute the processing logic
                try await DailyProcessingService.shared.processDailyMetrics()
                task.setTaskCompleted(success: true)
            } catch {
                print("Background processing failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }
}
