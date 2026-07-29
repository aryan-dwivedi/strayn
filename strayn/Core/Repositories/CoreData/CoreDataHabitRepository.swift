//
//  CoreDataHabitRepository.swift
//  strayn
//

import Foundation
import CoreData

class CoreDataHabitRepository: HabitRepositoryProtocol {
    static let shared = CoreDataHabitRepository()
    private let container: NSPersistentContainer
    
    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }
    
    func saveHabitEntry(_ entry: HabitEntry) async throws {
        let context = container.viewContext
        
        let fetchRequest: NSFetchRequest<HabitEntryEntity> = HabitEntryEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "habitId == %@", entry.habitId),
            NSPredicate(format: "date == %@", Calendar.current.startOfDay(for: entry.date) as NSDate)
        ])
        
        let existing = try context.fetch(fetchRequest)
        let entity = existing.first ?? HabitEntryEntity(context: context)
        
        entity.update(from: entry)
        
        try context.save()
    }
    
    func getHabitEntries(from startDate: Date, to endDate: Date) async throws -> [HabitEntry] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<HabitEntryEntity> = HabitEntryEntity.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \HabitEntryEntity.date, ascending: true)]
        
        let entities = try context.fetch(fetchRequest)
        return entities.map { $0.toDomainModel() }
    }
    
    func getHabitEntries(for date: Date) async throws -> [HabitEntry] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<HabitEntryEntity> = HabitEntryEntity.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
        
        let entities = try context.fetch(fetchRequest)
        return entities.map { $0.toDomainModel() }
    }
}
