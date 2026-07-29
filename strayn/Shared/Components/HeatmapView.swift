//
//  HeatmapView.swift
//  strayn
//
//  Created by Aryan Dwivedi on 18/01/26.
//

import SwiftUI

struct HeatmapView: View {
    let data: [Date: Double] // Date -> Score (0.0 to 1.0)
    let title: String
    
    // Grid Configuration
    let columns = Array(repeating: GridItem(.fixed(12), spacing: 4), count: 20) // Last 20 weeks roughly? Or optimize for screen width
    let days = 7
    let weeks = 14
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundColor(.gray)
            
            // Git-style grid
            // We need to render columns of weeks
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(0..<weeks, id: \.self) { week in
                        VStack(spacing: 4) {
                            ForEach(0..<days, id: \.self) { day in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(colorFor(week: week, day: day))
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private func colorFor(week: Int, day: Int) -> Color {
        // Calculate date from end (today) backwards
        // This is a simplified logic for mockup. In real app, map exact dates.
        let totalDays = weeks * 7
        let currentDayIndex = (week * 7) + day
        let daysAgo = totalDays - currentDayIndex
        
        // Random "data" simulation if key missing
        // For real usage, look up `data[date]`
        
        let score = Double.random(in: 0...1)
        
        if score > 0.8 { return .green }
        if score > 0.5 { return .yellow }
        if score > 0.2 { return .orange }
        return .gray.opacity(0.3)
    }
}
