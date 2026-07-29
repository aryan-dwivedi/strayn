//
//  HabitRepositoryProtocol.swift
//  strayn
//

import Foundation

protocol HabitRepositoryProtocol {
    func saveHabitEntry(_ entry: HabitEntry) async throws
    func getHabitEntries(from startDate: Date, to endDate: Date) async throws -> [HabitEntry]
    func getHabitEntries(for date: Date) async throws -> [HabitEntry]
}
