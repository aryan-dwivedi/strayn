//
//  UserRepositoryProtocol.swift
//  strayn
//
//  Protocol defining user data access operations
//

import Foundation

protocol UserRepositoryProtocol {
    /// Get the current user (should only be one user per device)
    func getCurrentUser() async throws -> User?

    /// Create or update user
    func saveUser(_ user: User) async throws

    /// Delete user and all associated data
    func deleteUser(_ user: User) async throws

    /// Check if onboarding is completed
    func isOnboardingCompleted() async throws -> Bool

    /// Update premium status
    func updatePremiumStatus(isPremium: Bool) async throws
}
