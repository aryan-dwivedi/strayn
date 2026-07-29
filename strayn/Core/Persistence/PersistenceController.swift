//
//  PersistenceController.swift
//  strayn
//
//  CoreData persistence controller with CloudKit sync support
//

import CoreData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()

    /// Preview instance for SwiftUI previews (in-memory)
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)

        // Add sample data for previews
        let context = controller.container.viewContext

        // Sample user
        let user = UserEntity(context: context)
        user.id = UUID()
        user.age = 30
        user.biologicalSex = "male"
        user.sleepNeedHours = 8.0
        user.onboardingCompleted = true
        user.isPremiumUser = false
        user.createdAt = Date()
        user.updatedAt = Date()

        // Sample recovery
        let recovery = DailyRecoveryEntity(context: context)
        recovery.id = UUID()
        recovery.date = Date()
        recovery.recoveryScore = 75.0
        recovery.recoveryZone = "green"
        recovery.hrvScore = 80.0
        recovery.restingHRScore = 70.0
        recovery.sleepScore = 75.0
        recovery.respiratoryRateScore = 80.0
        recovery.calculatedAt = Date()
        recovery.hasInsufficientData = false
        recovery.dataQualityScore = 0.95

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "strayn")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Ensure the Application Support directory exists
            let storeURL = Self.defaultStoreURL()
            if let storeDir = storeURL?.deletingLastPathComponent() {
                try? FileManager.default.createDirectory(at: storeDir, withIntermediateDirectories: true)
            }
            
            if let storeURL = storeURL {
                container.persistentStoreDescriptions.first?.url = storeURL
            }
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                // Handle migration or corruption
                self.handlePersistentStoreError(error, description: description)
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    /// Default store URL in Application Support
    private static func defaultStoreURL() -> URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let storeDir = appSupport.appendingPathComponent("strayn", isDirectory: true)
        return storeDir.appendingPathComponent("strayn.sqlite")
    }

    /// Handle persistent store loading errors
    private func handlePersistentStoreError(_ error: Error, description: NSPersistentStoreDescription) {
        let nsError = error as NSError

        // Log error
        print("CoreData failed to load: \(nsError), \(nsError.userInfo)")

        // Attempt recovery: delete and recreate store
        if let storeURL = description.url, storeURL.path != "/dev/null" {
            do {
                // Remove all related files (.sqlite, .sqlite-shm, .sqlite-wal)
                let storePath = storeURL.path
                let relatedFiles = [
                    storeURL,
                    URL(fileURLWithPath: storePath + "-shm"),
                    URL(fileURLWithPath: storePath + "-wal")
                ]
                
                for file in relatedFiles {
                    if FileManager.default.fileExists(atPath: file.path) {
                        try FileManager.default.removeItem(at: file)
                        print("Deleted: \(file.lastPathComponent)")
                    }
                }
                
                print("Deleted corrupted store, will recreate on next launch")
                
                // Don't try to reload in same session - just continue without persistence
                // The app will work with in-memory data and recreate store on next launch
                
            } catch {
                print("Failed to delete corrupted store: \(error)")
                // Continue anyway - app will work with limited functionality
            }
        }
        
        // Don't crash - allow the app to continue
        print("CoreData persistence unavailable - running with limited functionality")
    }

    /// Save context if there are changes
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    /// Create a background context for heavy operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Perform a task on a background context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
}
