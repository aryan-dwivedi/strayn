//
//  Goal.swift
//  strayn
//

import Foundation

struct Goal: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let targetMetrics: [String: String]
}
