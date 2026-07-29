//
//  AchievementsView.swift
//  strayn
//
//  Created by Aryan Dwivedi on 18/01/26.
//

import SwiftUI

struct AchievementsView: View {
    @StateObject private var system = AchievementSystem.shared
    @State private var selectedCategory: AchievementCategory?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return system.achievements.filter { $0.category == category }
        }
        return system.achievements
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        
                        // Category Picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                categoryTab(title: "All", category: nil)
                                ForEach(AchievementCategory.allCases, id: \.self) { cat in
                                    categoryTab(title: cat.rawValue.capitalized, category: cat)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Grid
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(filteredAchievements) { achievement in
                                achievementCard(achievement)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Awards")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            
            Text("\(system.achievements.filter { $0.isUnlocked }.count) of \(system.achievements.count) unlocked")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    private func categoryTab(title: String, category: AchievementCategory?) -> some View {
        Button(action: {
            HapticsManager.shared.playSelection()
            selectedCategory = category
        }) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(selectedCategory == category ? .black : .gray)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(selectedCategory == category ? Color.white : Color.white.opacity(0.05))
                .cornerRadius(20)
        }
    }
    
    private func achievementCard(_ achievement: Achievement) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.blue.opacity(0.1) : Color.white.opacity(0.05))
                    .frame(width: 80, height: 80)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 30))
                    .foregroundColor(achievement.isUnlocked ? .blue : .gray.opacity(0.5))
                
                if !achievement.isUnlocked {
                    Circle()
                        .trim(from: 0, to: achievement.progress)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                }
            }
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(achievement.isUnlocked ? .white : .gray)
                    .multilineTextAlignment(.center)
                
                Text(achievement.description)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(height: 180)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(achievement.isUnlocked ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}
