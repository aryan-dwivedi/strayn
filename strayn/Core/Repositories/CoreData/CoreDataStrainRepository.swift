//
//  CoreDataStrainRepository.swift
//  strayn
//
//  CoreData implementation of StrainRepositoryProtocol
//

import Foundation
import CoreData
import Combine

class CoreDataStrainRepository: StrainRepositoryProtocol {
    static let shared = CoreDataStrainRepository()

    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    func getStrain(for date: Date) async throws -> DailyStrain? {
        let context = persistenceController.container.viewContext
        let startOfDay = Calendar.current.startOfDay(for: date)

        let fetchRequest: NSFetchRequest<DailyStrainEntity> = DailyStrainEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", startOfDay as CVarArg)
        fetchRequest.fetchLimit = 1

        let entities = try context.fetch(fetchRequest)
        return entities.first?.toDomainModel()
    }

    func getStrains(from startDate: Date, to endDate: Date) async throws -> [DailyStrain] {
        let context = persistenceController.container.viewContext
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)

        let fetchRequest: NSFetchRequest<DailyStrainEntity> = DailyStrainEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", start as CVarArg, end as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        let entities = try context.fetch(fetchRequest)
        return entities.compactMap { $0.toDomainModel() }
    }

    func getRecentStrains(days: Int) async throws -> [DailyStrain] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        return try await getStrains(from: startDate, to: endDate)
    }

    func saveStrain(_ strain: DailyStrain) async throws {
        let context = persistenceController.container.viewContext
        let startOfDay = Calendar.current.startOfDay(for: strain.date)

        let fetchRequest: NSFetchRequest<DailyStrainEntity> = DailyStrainEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", startOfDay as CVarArg)
        fetchRequest.fetchLimit = 1

        let existingEntities = try context.fetch(fetchRequest)
        let entity: DailyStrainEntity

        if let existing = existingEntities.first {
            entity = existing
        } else {
            entity = DailyStrainEntity(context: context)
        }

        entity.update(from: strain)
        try context.save()
    }

    func updateStrain(_ strain: DailyStrain) async throws {
        try await saveStrain(strain)
    }

    func deleteStrain(_ strain: DailyStrain) async throws {
        let context = persistenceController.container.viewContext
        let startOfDay = Calendar.current.startOfDay(for: strain.date)

        let fetchRequest: NSFetchRequest<DailyStrainEntity> = DailyStrainEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", startOfDay as CVarArg)

        let entities = try context.fetch(fetchRequest)
        for entity in entities {
            context.delete(entity)
        }

        try context.save()
    }

    func deleteStrainsOlderThan(days: Int) async throws {
        let context = persistenceController.container.viewContext
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let startOfCutoff = Calendar.current.startOfDay(for: cutoffDate)

        let fetchRequest: NSFetchRequest<DailyStrainEntity> = DailyStrainEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date < %@", startOfCutoff as CVarArg)

        let entities = try context.fetch(fetchRequest)
        for entity in entities {
            context.delete(entity)
        }

        try context.save()
    }

    func getAverageStrain(for days: Int) async throws -> Double? {
        let strains = try await getRecentStrains(days: days)
        guard !strains.isEmpty else { return nil }
        let total = strains.reduce(0.0) { $0 + $1.strainScore }
        return total / Double(strains.count)
    }

    func getTodayStrain() async throws -> DailyStrain? {
        return try await getStrain(for: Date())
    }
}

// MARK: - DailyStrainEntity Extensions

extension DailyStrainEntity {
    func toDomainModel() -> DailyStrain {
        return DailyStrain(
            id: id ?? UUID(),
            date: date ?? Date(),
            strainScore: strainScore,
            timeInZone1: timeInZone1,
            timeInZone2: timeInZone2,
            timeInZone3: timeInZone3,
            timeInZone4: timeInZone4,
            timeInZone5: timeInZone5,
            workoutStrain: workoutStrain,
            dailyActivityStrain: dailyActivityStrain,
            workoutIds: [], // Placeholder
            lastUpdated: lastUpdated ?? Date(),
            isComplete: isComplete
        )
    }

    func update(from strain: DailyStrain) {
        self.id = strain.id
        self.date = Calendar.current.startOfDay(for: strain.date)
        self.strainScore = strain.strainScore
        self.timeInZone1 = strain.timeInZone1
        self.timeInZone2 = strain.timeInZone2
        self.timeInZone3 = strain.timeInZone3
        self.timeInZone4 = strain.timeInZone4
        self.timeInZone5 = strain.timeInZone5
        self.workoutStrain = strain.workoutStrain
        self.dailyActivityStrain = strain.dailyActivityStrain
        self.lastUpdated = strain.lastUpdated
        self.isComplete = strain.isComplete
    }
}

extension DailyStrainEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyStrainEntity> {
        return NSFetchRequest<DailyStrainEntity>(entityName: "DailyStrainEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var strainScore: Double
    @NSManaged public var timeInZone1: Double
    @NSManaged public var timeInZone2: Double
    @NSManaged public var timeInZone3: Double
    @NSManaged public var timeInZone4: Double
    @NSManaged public var timeInZone5: Double
    @NSManaged public var workoutStrain: Double
    @NSManaged public var dailyActivityStrain: Double
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var isComplete: Bool
    @NSManaged public var user: UserEntity?
}
