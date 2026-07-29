//
//  HabitEntryEntity+CoreDataClass.swift
//  strayn
//

import Foundation
import CoreData

@objc(HabitEntryEntity)
public class HabitEntryEntity: NSManagedObject {
    func toDomainModel() -> HabitEntry {
        return HabitEntry(
            id: id ?? UUID(),
            habitId: habitId ?? "",
            date: date ?? Date(),
            value: value ?? "",
            timestamp: timestamp ?? Date()
        )
    }

    func update(from entry: HabitEntry) {
        self.id = entry.id
        self.habitId = entry.habitId
        self.date = Calendar.current.startOfDay(for: entry.date)
        self.value = entry.value
        self.timestamp = entry.timestamp
    }
}

extension HabitEntryEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<HabitEntryEntity> {
        return NSFetchRequest<HabitEntryEntity>(entityName: "HabitEntryEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var habitId: String?
    @NSManaged public var date: Date?
    @NSManaged public var value: String?
    @NSManaged public var timestamp: Date?
}
