//
//  CoreDataUserRepository.swift
//  strayn
//
//  CoreData implementation of UserRepositoryProtocol
//

import Foundation
import CoreData
import Combine

class CoreDataUserRepository: UserRepositoryProtocol {
    static let shared = CoreDataUserRepository()

    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    func getCurrentUser() async throws -> User? {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.fetchLimit = 1

        let entities = try context.fetch(fetchRequest)
        return entities.first?.toDomainModel()
    }

    func saveUser(_ user: User) async throws {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.fetchLimit = 1

        let entities = try context.fetch(fetchRequest)
        let entity: UserEntity

        if let existing = entities.first {
            entity = existing
        } else {
            entity = UserEntity(context: context)
        }

        entity.update(from: user)
        try context.save()
    }

    func deleteUser(_ user: User) async throws {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", user.id as CVarArg)

        let entities = try context.fetch(fetchRequest)
        for entity in entities {
            context.delete(entity)
        }

        try context.save()
    }

    func isOnboardingCompleted() async throws -> Bool {
        let user = try await getCurrentUser()
        return user?.onboardingCompleted ?? false
    }

    func updatePremiumStatus(isPremium: Bool) async throws {
        guard var user = try await getCurrentUser() else { return }
        user.isPremiumUser = isPremium
        try await saveUser(user)
    }
}
