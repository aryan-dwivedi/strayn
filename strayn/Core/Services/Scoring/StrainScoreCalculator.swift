//
//  StrainScoreCalculator.swift
//  strayn
//
//  Calculates daily cardiovascular strain based on heart rate samples
//

import Foundation
import HealthKit

class StrainScoreCalculator {
    static let shared = StrainScoreCalculator()
    
    private init() {}
    
    /// Calculate strain score for a given day
    /// - Parameters:
    ///   - date: The date for which to calculate strain
    ///   - heartRateSamples: All HR samples for the day
    ///   - maxHR: User's maximum heart rate
    ///   - workouts: Workouts recorded for the day
    /// - Returns: A DailyStrain object containing the calculated score and zone breakdowns
    func calculateStrain(
        date: Date,
        heartRateSamples: [HKQuantitySample],
        maxHR: Int,
        workouts: [HKWorkout] = []
    ) -> DailyStrain {
        
        let zones = HeartRateZone.calculateZones(maxHR: maxHR)
        
        var zoneDurations: [Int: TimeInterval] = [
            1: 0, 2: 0, 3: 0, 4: 0, 5: 0
        ]
        
        var totalPoints = 0.0
        
        // 1. Process samples to calculate time in zones and intensity points
        // We approximate duration between samples
        
        for i in 0..<heartRateSamples.count {
            let sample = heartRateSamples[i]
            let hrValue = Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
            
            // Determine duration (time until next sample, or 1 minute default)
            var duration: TimeInterval = 60.0
            if i < heartRateSamples.count - 1 {
                duration = heartRateSamples[i+1].startDate.timeIntervalSince(sample.startDate)
                // Cap duration to 5 minutes to avoid huge gaps inflating strain
                duration = min(duration, 300.0)
            }
            
            let zoneNumber = HeartRateZone.zone(for: hrValue, maxHR: maxHR)
            zoneDurations[zoneNumber, default: 0] += duration
            
            // Weight points by zone intensity (exponential matching)
            if let zone = zones.first(where: { $0.zone == zoneNumber }) {
                totalPoints += (duration / 60.0) * zone.strainWeight
            }
        }
        
        // 2. Map Points to 0-21 Logarithmic Scale
        // We use a log scale so that higher strain is increasingly harder to earn.
        // Formula: score = log(points + 1) * multiplier
        // We want ~500 points to equal 21 (Elite workout)
        
        let strainScore = totalPoints > 0 ? min(21.0, log(totalPoints + 1) * 3.38) : 0.0
        
        // 3. Separate workout strain (Optional: for more detailed breakdown)
        // For now, let's just calculate total and mark if workouts were present
        
        return DailyStrain(
            date: date,
            strainScore: strainScore,
            timeInZone1: zoneDurations[1] ?? 0,
            timeInZone2: zoneDurations[2] ?? 0,
            timeInZone3: zoneDurations[3] ?? 0,
            timeInZone4: zoneDurations[4] ?? 0,
            timeInZone5: zoneDurations[5] ?? 0,
            workoutIds: workouts.map { $0.uuid.uuidString },
            isComplete: Calendar.current.isDateInToday(date) == false
        )
    }
}
