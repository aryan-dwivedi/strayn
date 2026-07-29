//
//  straynApp.swift
//  strayn
//
//  Created by Aryan Dwivedi on 18/01/26.
//

import SwiftUI
import Combine
import CoreData

@main
struct straynApp: App {
    let persistenceController = PersistenceController.shared
    let backgroundService = BackgroundTaskService.shared
    @StateObject private var appState = AppState.shared
    @Environment(\.scenePhase) var scenePhase

    init() {
        backgroundService.registerTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !appState.isOnboardingComplete {
                    WHOOPStyleOnboardingView()
                } else if appState.isAppLocked {
                    // Lock Screen
                    VStack(spacing: 20) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("Strayn Locked")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Button("Unlock") {
                            SecurityManager.shared.authenticate { success in
                                appState.isAppLocked = !success
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .onAppear {
                        SecurityManager.shared.authenticate { success in
                            appState.isAppLocked = !success
                        }
                    }
                } else {
                    MainTabView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .onAppear {
                            backgroundService.scheduleDailyRecovery()
                        }
                }
            }
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .active:
                    appState.appDidBecomeActive()
                case .inactive, .background:
                    appState.appWillResignActive()
                @unknown default:
                    break
                }
            }
        }
    }
}
