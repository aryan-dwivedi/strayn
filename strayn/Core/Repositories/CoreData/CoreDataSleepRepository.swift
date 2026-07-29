//
//  CoreDataSleepRepository.swift
//  strayn
//
//  CoreData implementation of SleepRepositoryProtocol
//

import Foundation
import CoreData
import Combine

class CoreDataSleepRepository: SleepRepositoryProtocol {
    static let shared = CoreDataSleepRepository()

    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    func getLastSleep() async throws -> SleepSession? {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<SleepSessionEntity> = SleepSessionEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.fetchLimit = 1

        let entities = try context.fetch(fetchRequest)
        return entities.first?.toDomainModel()
    }

    func getSleep(for date: Date) async throws -> SleepSession? {
        let context = persistenceController.container.viewContext
        let startOfDay = Calendar.current.startOfDay(for: date)

        let fetchRequest: NSFetchRequest<SleepSessionEntity> = SleepSessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", startOfDay as CVarArg)
        fetchRequest.fetchLimit = 1

        let entities = try context.fetch(fetchRequest)
        return entities.first?.toDomainModel()
    }

    func getSleepSessions(from startDate: Date, to endDate: Date) async throws -> [SleepSession] {
        let context = persistenceController.container.viewContext
        let startRequest = Calendar.current.startOfDay(for: startDate)
        let endRequest = Calendar.current.startOfDay(for: endDate)

        let fetchRequest: NSFetchRequest<SleepSessionEntity> = SleepSessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startRequest as CVarArg, endRequest as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        let entities = try context.fetch(fetchRequest)
        return entities.compactMap { $0.toDomainModel() }
    }

    func getRecentSleepSessions(count: Int) async throws -> [SleepSession] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<SleepSessionEntity> = SleepSessionEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.fetchLimit = count

        let entities = try context.fetch(fetchRequest)
        return entities.compactMap { $0.toDomainModel() }.reversed()
    }

    func saveSleepSession(_ session: SleepSession) async throws {
        let context = persistenceController.container.viewContext
        let startOfDay = Calendar.current.startOfDay(for: session.date)

        let fetchRequest: NSFetchRequest<SleepSessionEntity> = SleepSessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", startOfDay as CVarArg)
        fetchRequest.fetchLimit = 1

        let existingEntities = try context.fetch(fetchRequest)
        let entity: SleepSessionEntity

        if let existing = existingEntities.first {
            entity = existing
        } else {
            entity = SleepSessionEntity(context: context)
        }

        entity.update(from: session)
        try context.save()
    }

    func deleteSleepSession(_ session: SleepSession) async throws {
        let context = persistenceController.container.viewContext
        let startOfDay = Calendar.current.startOfDay(for: session.date)

        let fetchRequest: NSFetchRequest<SleepSessionEntity> = SleepSessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", startOfDay as CVarArg)

        let entities = try context.fetch(fetchRequest)
        for entity in entities {
            context.delete(entity)
        }

        try context.save()
    }

    func calculateSleepDebt() async throws -> TimeInterval {
        let sessions = try await getRecentSleepSessions(count: 7)
        let totalDebt = sessions.reduce(0.0) { $0 + $1.sleepDebt }
        return totalDebt
    }

    func getAverageSleepDuration(for days: Int) async throws -> TimeInterval? {
        let sessions = try await getRecentSleepSessions(count: days)
        guard !sessions.isEmpty else { return nil }
        let total = sessions.reduce(0.0) { $0 + $1.totalDuration }
        return total / Double(sessions.count)
    }

    func getAverageSleepEfficiency(for days: Int) async throws -> Double? {
        let sessions = try await getRecentSleepSessions(count: days)
        guard !sessions.isEmpty else { return nil }
        let total = sessions.reduce(0.0) { $0 + $1.sleepEfficiency }
        return total / Double(sessions.count)
    }
}

// MARK: - SleepSessionEntity Extensions

extension SleepSessionEntity {
    func toDomainModel() -> SleepSession {
        return SleepSession(
            id: id ?? UUID(),
            date: date ?? Date(),
            startDate: startTime ?? Date(),
            endDate: endTime ?? Date(),
            totalDuration: totalDuration,
            inBedDuration: totalDuration / efficiency, // Heuristic since we didn't store it separately
            sleepEfficiency: efficiency,
            deepSleepDuration: deepSleepDuration,
            remSleepDuration: remSleepDuration,
            coreSleepDuration: coreSleepDuration,
            awakeDuration: awakeDuration,
            sleepNeed: 28800, // Default 8h
            sleepDebt: sleepDebt
        )
    }

    func update(from session: SleepSession) {
        self.id = session.id
        self.date = Calendar.current.startOfDay(for: session.date)
        self.startTime = session.startDate
        self.endTime = session.endDate
        self.totalDuration = session.totalDuration
        self.deepSleepDuration = session.deepSleepDuration ?? 0
        self.coreSleepDuration = session.coreSleepDuration ?? 0
        self.remSleepDuration = session.remSleepDuration ?? 0
        self.awakeDuration = session.awakeDuration
        self.efficiency = session.sleepEfficiency
        self.sleepDebt = session.sleepDebt
    }
}

extension SleepSessionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SleepSessionEntity> {
        return NSFetchRequest<SleepSessionEntity>(entityName: "SleepSessionEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var totalDuration: Double
    @NSManaged public var deepSleepDuration: Double
    @NSManaged public var coreSleepDuration: Double
    @NSManaged public var remSleepDuration: Double
    @NSManaged public var awakeDuration: Double
    @NSManaged public var efficiency: Double
    @NSManaged public var sleepDebt: Double
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var user: UserEntity?
}
