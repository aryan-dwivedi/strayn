//
//  UserEntity+CoreDataClass.swift
//  strayn
//
//  CoreData entity for User
//

import Foundation
import CoreData

@objc(UserEntity)
public class UserEntity: NSManagedObject {
    /// Convert to domain model
    func toDomainModel() -> User {
        return User(
            id: id ?? UUID(),
            age: Int(age),
            biologicalSex: User.BiologicalSex(rawValue: biologicalSex ?? "other") ?? .other,
            maxHeartRate: maxHeartRate > 0 ? Int(maxHeartRate) : nil,
            restingHeartRateTrend: restingHeartRateTrend > 0 ? restingHeartRateTrend : nil,
            hasMenstrualCycle: hasMenstrualCycle,
            sleepNeedHours: sleepNeedHours,
            onboardingCompleted: onboardingCompleted,
            isPremiumUser: isPremiumUser,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }

    /// Update from domain model
    func update(from user: User) {
        self.id = user.id
        self.age = Int16(user.age)
        self.biologicalSex = user.biologicalSex.rawValue
        self.maxHeartRate = Int16(user.maxHeartRate ?? 0)
        self.restingHeartRateTrend = user.restingHeartRateTrend ?? 0
        self.hasMenstrualCycle = user.hasMenstrualCycle
        self.sleepNeedHours = user.sleepNeedHours
        self.onboardingCompleted = user.onboardingCompleted
        self.isPremiumUser = user.isPremiumUser
        self.createdAt = user.createdAt
        self.updatedAt = user.updatedAt
    }
}

extension UserEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var age: Int16
    @NSManaged public var biologicalSex: String?
    @NSManaged public var maxHeartRate: Int16
    @NSManaged public var restingHeartRateTrend: Double
    @NSManaged public var hasMenstrualCycle: Bool
    @NSManaged public var sleepNeedHours: Double
    @NSManaged public var onboardingCompleted: Bool
    @NSManaged public var isPremiumUser: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var dailyRecoveries: NSSet?
    @NSManaged public var dailyStrains: NSSet?
    @NSManaged public var sleepSessions: NSSet?
    @NSManaged public var baselines: NSSet?
}
