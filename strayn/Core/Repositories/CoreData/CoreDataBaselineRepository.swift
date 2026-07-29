//
//  CoreDataBaselineRepository.swift
//  strayn
//
//  CoreData implementation of BaselineRepositoryProtocol
//

import Foundation
import CoreData
import Combine

class CoreDataBaselineRepository: BaselineRepositoryProtocol {
    static let shared = CoreDataBaselineRepository()

    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    func getBaseline(for metric: Baseline.BaselineMetric, userId: UUID) async throws -> Baseline? {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<BaselineEntity> = BaselineEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "metric == %@ AND userId == %@", metric.rawValue, userId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "calculatedAt", ascending: false)]
        fetchRequest.fetchLimit = 1

        let entities = try context.fetch(fetchRequest)
        return entities.first?.toDomainModel()
    }

    func getAllBaselines(for userId: UUID) async throws -> [Baseline] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<BaselineEntity> = BaselineEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)

        let entities = try context.fetch(fetchRequest)
        
        // Group by metric and take the latest for each
        var latestBaselines: [Baseline.BaselineMetric: Baseline] = [:]
        for entity in entities {
            if let model = entity.toDomainModel(), let metric = Baseline.BaselineMetric(rawValue: entity.metric ?? "") {
                if let existing = latestBaselines[metric] {
                    if model.calculatedAt > existing.calculatedAt {
                        latestBaselines[metric] = model
                    }
                } else {
                    latestBaselines[metric] = model
                }
            }
        }
        
        return Array(latestBaselines.values)
    }

    func saveBaseline(_ baseline: Baseline) async throws {
        let context = persistenceController.container.viewContext
        let entity = BaselineEntity(context: context)
        entity.update(from: baseline)
        try context.save()
    }

    func deleteBaseline(_ baseline: Baseline) async throws {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<BaselineEntity> = BaselineEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", baseline.id as CVarArg)

        let entities = try context.fetch(fetchRequest)
        for entity in entities {
            context.delete(entity)
        }

        try context.save()
    }

    func getBaselineHistory(for metric: Baseline.BaselineMetric, userId: UUID, limit: Int) async throws -> [Baseline] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<BaselineEntity> = BaselineEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "metric == %@ AND userId == %@", metric.rawValue, userId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "calculatedAt", ascending: false)]
        fetchRequest.fetchLimit = limit

        let entities = try context.fetch(fetchRequest)
        return entities.compactMap { $0.toDomainModel() }
    }
}

// MARK: - BaselineEntity Extensions

extension BaselineEntity {
    func toDomainModel() -> Baseline? {
        guard let metricRaw = metric, let metric = Baseline.BaselineMetric(rawValue: metricRaw) else {
            return nil
        }
        
        return Baseline(
            id: id ?? UUID(),
            userId: userId ?? UUID(),
            metric: metric,
            mean: mean,
            standardDeviation: standardDeviation,
            median: median > 0 ? median : nil,
            startDate: startDate ?? Date(),
            endDate: endDate ?? Date(),
            sampleCount: Int(sampleCount),
            windowDays: Int(windowDays),
            trend: Baseline.TrendDirection(rawValue: trend ?? "") ?? .stable,
            trendSlope: trendSlope,
            calculatedAt: calculatedAt ?? Date(),
            isValid: isValid
        )
    }

    func update(from baseline: Baseline) {
        self.id = baseline.id
        self.userId = baseline.userId
        self.metric = baseline.metric.rawValue
        self.mean = baseline.mean
        self.standardDeviation = baseline.standardDeviation
        self.median = baseline.median ?? 0
        self.startDate = baseline.startDate
        self.endDate = baseline.endDate
        self.sampleCount = Int16(baseline.sampleCount)
        self.windowDays = Int16(baseline.windowDays)
        self.trend = baseline.trend?.rawValue
        self.trendSlope = baseline.trendSlope ?? 0
        self.calculatedAt = baseline.calculatedAt
        self.isValid = baseline.isValid
    }
}

extension BaselineEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BaselineEntity> {
        return NSFetchRequest<BaselineEntity>(entityName: "BaselineEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var userId: UUID?
    @NSManaged public var metric: String?
    @NSManaged public var mean: Double
    @NSManaged public var standardDeviation: Double
    @NSManaged public var median: Double
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var sampleCount: Int16
    @NSManaged public var windowDays: Int16
    @NSManaged public var trend: String?
    @NSManaged public var trendSlope: Double
    @NSManaged public var calculatedAt: Date?
    @NSManaged public var isValid: Bool
}
