//
//  MainTabView.swift
//  strayn
//
//  Created by Aryan Dwivedi on 18/01/26.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppState.shared
    
    // Initialize temporary views if they don't exist yet
    // In a real scenario, these would be the actual Views from their features
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Today", systemImage: "circle.circle")
                }
                .tag(TabIdentifier.dashboard)
            
            HistoryView()
                .tabItem {
                    Label("Trends", systemImage: "chart.bar.xaxis")
                }
                .tag(TabIdentifier.history)
            
            AchievementsView()
                .tabItem {
                    Label("Awards", systemImage: "trophy")
                }
                .tag(TabIdentifier.achievements)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(TabIdentifier.profile)
        }
        .accentColor(.white) // Premium feel
        .onAppear {
            // Fix for iOS 15+ TabBar appearance transparency
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.black
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
}
