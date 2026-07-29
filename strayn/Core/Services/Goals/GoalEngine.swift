//
//  GoalEngine.swift
//  strayn
//
//  Created by Aryan Dwivedi on 18/01/26.
//

import Foundation
import Combine

enum GoalType: String, CaseIterable, Identifiable, Codable {
    case longevity
    case performance
    case stressManagement
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .longevity: return "Longevity"
        case .performance: return "Peak Performance"
        case .stressManagement: return "Stress Management"
        }
    }
    
    var description: String {
        switch self {
        case .longevity: return "Focus on long-term health span and vital preservation."
        case .performance: return "Optimize for athletic output and rapid recovery."
        case .stressManagement: return "Balance autonomic nervous system and reduce load."
        }
    }
    
    var icon: String {
        switch self {
        case .longevity: return "leaf.fill"
        case .performance: return "bolt.fill"
        case .stressManagement: return "brain.head.profile"
        }
    }
}

class GoalEngine: ObservableObject {
    static let shared = GoalEngine()
    
    @Published var selectedGoal: GoalType = .longevity {
        didSet {
            UserDefaults.standard.set(selectedGoal.rawValue, forKey: "selectedGoal")
        }
    }
    
    var availableGoals: [GoalType] {
        return GoalType.allCases
    }
    
    private init() {
        if let savedGoal = UserDefaults.standard.string(forKey: "selectedGoal"),
           let goal = GoalType(rawValue: savedGoal) {
            self.selectedGoal = goal
        }
    }
}
