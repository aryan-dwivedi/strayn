//
//  ReportService.swift
//  strayn
//
//  Handles generation of weekly health summaries and shareable reports.
//

import Foundation
import UIKit

class ReportService {
    static let shared = ReportService()
    
    private init() {}
    
    struct WeeklySummary {
        let averageRecovery: Int
        let totalStrain: Double
        let sleepPerformance: Int
        let straynAgeDelta: Double
    }
    
    func generateWeeklySummary() -> WeeklySummary {
        // Mock data based on 30-day history
        return WeeklySummary(
            averageRecovery: 72,
            totalStrain: 94.5,
            sleepPerformance: 88,
            straynAgeDelta: -2.4
        )
    }
    
    func shareWeeklyReport() {
        let summary = generateWeeklySummary()
        let text = """
        My Weekly Strayn Report:
        - Avg Recovery: \(summary.averageRecovery)%
        - Total Strain: \(summary.totalStrain)
        - Sleep Performance: \(summary.sleepPerformance)%
        - Strayn Age: \(summary.straynAgeDelta > 0 ? "+" : "")\(summary.straynAgeDelta) years delta
        
        Join me on Strayn for Biological Intelligence.
        """
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }
}
