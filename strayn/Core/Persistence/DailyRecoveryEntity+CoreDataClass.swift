//
//  DailyRecoveryEntity+CoreDataClass.swift
//  strayn
//
//  CoreData entity for DailyRecovery
//

import Foundation
import CoreData

@objc(DailyRecoveryEntity)
public class DailyRecoveryEntity: NSManagedObject {
    func toDomainModel() -> DailyRecovery {
        return DailyRecovery(
            id: id ?? UUID(),
            date: date ?? Date(),
            recoveryScore: recoveryScore,
            recoveryZone: DailyRecovery.RecoveryZone(rawValue: recoveryZone ?? "red") ?? .red,
            hrvScore: hrvScore,
            restingHRScore: restingHRScore,
            sleepScore: sleepScore,
            respiratoryRateScore: respiratoryRateScore,
            rawHRV: rawHRV > 0 ? rawHRV : nil,
            rawRestingHR: rawRestingHR > 0 ? rawRestingHR : nil,
            rawSleepDuration: rawSleepDuration > 0 ? rawSleepDuration : nil,
            rawRespiratoryRate: rawRespiratoryRate > 0 ? rawRespiratoryRate : nil,
            hrvBaseline: hrvBaseline > 0 ? hrvBaseline : nil,
            restingHRBaseline: restingHRBaseline > 0 ? restingHRBaseline : nil,
            autonomicBalance: autonomicBalance,
            stressLoad: stressLoad,
            cardiacEfficiency: cardiacEfficiency,
            recoveryContributors: decodeContributors(),
            straynAge: straynAge,
            calculatedAt: calculatedAt ?? Date(),
            hasInsufficientData: hasInsufficientData,
            dataQualityScore: dataQualityScore,
            journalData: journalData
        )
    }

    private func decodeContributors() -> [String: Double]? {
        guard let data = contributorsJSON?.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([String: Double].self, from: data)
    }

    func update(from recovery: DailyRecovery) {
        self.id = recovery.id
        self.date = Calendar.current.startOfDay(for: recovery.date)
        self.recoveryScore = recovery.recoveryScore
        self.recoveryZone = recovery.recoveryZone.rawValue
        self.hrvScore = recovery.hrvScore
        self.restingHRScore = recovery.restingHRScore
        self.sleepScore = recovery.sleepScore
        self.respiratoryRateScore = recovery.respiratoryRateScore
        self.rawHRV = recovery.rawHRV ?? 0
        self.rawRestingHR = recovery.rawRestingHR ?? 0
        self.rawSleepDuration = recovery.rawSleepDuration ?? 0
        self.rawRespiratoryRate = recovery.rawRespiratoryRate ?? 0
        self.hrvBaseline = recovery.hrvBaseline ?? 0
        self.restingHRBaseline = recovery.restingHRBaseline ?? 0
        self.autonomicBalance = recovery.autonomicBalance ?? 0
        self.stressLoad = recovery.stressLoad ?? 0
        self.cardiacEfficiency = recovery.cardiacEfficiency ?? 0
        self.straynAge = recovery.straynAge ?? 0
        
        if let contributors = recovery.recoveryContributors,
           let data = try? JSONEncoder().encode(contributors) {
            self.contributorsJSON = String(data: data, encoding: .utf8)
        }
        
        self.calculatedAt = recovery.calculatedAt
        self.hasInsufficientData = recovery.hasInsufficientData
        self.dataQualityScore = recovery.dataQualityScore
        self.journalData = recovery.journalData
    }
}

extension DailyRecoveryEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyRecoveryEntity> {
        return NSFetchRequest<DailyRecoveryEntity>(entityName: "DailyRecoveryEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var recoveryScore: Double
    @NSManaged public var recoveryZone: String?
    @NSManaged public var hrvScore: Double
    @NSManaged public var restingHRScore: Double
    @NSManaged public var sleepScore: Double
    @NSManaged public var respiratoryRateScore: Double
    @NSManaged public var rawHRV: Double
    @NSManaged public var rawRestingHR: Double
    @NSManaged public var rawSleepDuration: Double
    @NSManaged public var rawRespiratoryRate: Double
    @NSManaged public var hrvBaseline: Double
    @NSManaged public var restingHRBaseline: Double
    @NSManaged public var calculatedAt: Date?
    @NSManaged public var hasInsufficientData: Bool
    @NSManaged public var dataQualityScore: Double
    @NSManaged public var journalData: String?
    @NSManaged public var autonomicBalance: Double
    @NSManaged public var stressLoad: Double
    @NSManaged public var cardiacEfficiency: Double
    @NSManaged public var straynAge: Double
    @NSManaged public var contributorsJSON: String?
    @NSManaged public var user: UserEntity?
}
