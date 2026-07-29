//
//  Habit.swift
//  strayn
//

import Foundation

struct Habit: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let category: HabitCategory
    let impactDirection: ImpactDirection // Does doing this habit increase or decrease recovery?
    
    enum HabitCategory: String, Codable {
        case recovery
        case nutrition
        case activity
        case sleep
    }
    
    enum ImpactDirection: Int, Codable {
        case positive = 1
        case negative = -1
        case neutral = 0
    }
}

struct HabitEntry: Identifiable, Codable {
    let id: UUID
    let habitId: String
    let date: Date
    let value: String // "true", "1", "high", etc.
    let timestamp: Date
}
