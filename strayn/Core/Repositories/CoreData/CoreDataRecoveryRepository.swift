//
//  CoreDataRecoveryRepository.swift
//  strayn
//
//  CoreData implementation of RecoveryRepositoryProtocol
//

import Foundation
import CoreData
import Combine

class CoreDataRecoveryRepository: RecoveryRepositoryProtocol {
    static let shared = CoreDataRecoveryRepository()

    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    func getRecovery(for date: Date) async throws -> DailyRecovery? {
        let context = persistenceController.container.viewContext
        let startOfDay = Calendar.current.startOfDay(for: date)

        let fetchRequest: NSFetchRequest<DailyRecoveryEntity> = DailyRecoveryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", startOfDay as CVarArg)
        fetchRequest.fetchLimit = 1

        let entities = try context.fetch(fetchRequest)
        return entities.first?.toDomainModel()
    }

    func getRecoveries(from startDate: Date, to endDate: Date) async throws -> [DailyRecovery] {
        let context = persistenceController.container.viewContext
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)

        let fetchRequest: NSFetchRequest<DailyRecoveryEntity> = DailyRecoveryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", start as CVarArg, end as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        let entities = try context.fetch(fetchRequest)
        return entities.compactMap { $0.toDomainModel() }
    }

    func getRecentRecoveries(days: Int) async throws -> [DailyRecovery] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        return try await getRecoveries(from: startDate, to: endDate)
    }

    func saveRecovery(_ recovery: DailyRecovery) async throws {
        let context = persistenceController.container.viewContext

        // Check if entity already exists
        let startOfDay = Calendar.current.startOfDay(for: recovery.date)
        let fetchRequest: NSFetchRequest<DailyRecoveryEntity> = DailyRecoveryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", startOfDay as CVarArg)
        fetchRequest.fetchLimit = 1

        let existingEntities = try context.fetch(fetchRequest)
        let entity: DailyRecoveryEntity

        if let existing = existingEntities.first {
            entity = existing
        } else {
            entity = DailyRecoveryEntity(context: context)
        }

        // Update entity
        entity.update(from: recovery)

        // Save
        try context.save()
    }

    func deleteRecovery(_ recovery: DailyRecovery) async throws {
        let context = persistenceController.container.viewContext
        let startOfDay = Calendar.current.startOfDay(for: recovery.date)

        let fetchRequest: NSFetchRequest<DailyRecoveryEntity> = DailyRecoveryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", startOfDay as CVarArg)

        let entities = try context.fetch(fetchRequest)
        for entity in entities {
            context.delete(entity)
        }

        try context.save()
    }

    func deleteRecoveriesOlderThan(days: Int) async throws {
        let context = persistenceController.container.viewContext
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let startOfCutoff = Calendar.current.startOfDay(for: cutoffDate)

        let fetchRequest: NSFetchRequest<DailyRecoveryEntity> = DailyRecoveryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date < %@", startOfCutoff as CVarArg)

        let entities = try context.fetch(fetchRequest)
        for entity in entities {
            context.delete(entity)
        }

        try context.save()
    }

    func getAverageRecovery(for days: Int) async throws -> Double? {
        let recoveries = try await getRecentRecoveries(days: days)
        guard !recoveries.isEmpty else { return nil }

        let total = recoveries.reduce(0.0) { $0 + $1.recoveryScore }
        return total / Double(recoveries.count)
    }
}

// Entity extensions are in DailyRecoveryEntity+CoreDataClass.swift or already defined.
// If missing, they will be added there.
