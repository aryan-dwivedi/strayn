//
//  StraynHeatmapView.swift
//  strayn
//
//  A Git-style contribution graph for tracking recovery consistency.
//

import SwiftUI

struct StraynHeatmapView: View {
    let data: [Date: Double] // Date to Recovery Score (0-100)
    
    private let columns = Array(repeating: GridItem(.fixed(12), spacing: 4), count: 7)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consistency")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: columns, spacing: 4) {
                    ForEach(0..<90, id: \.self) { dayOffset in
                        let date = Calendar.current.date(byAdding: .day, value: -89 + dayOffset, to: Date())!
                        let score = data[Calendar.current.startOfDay(for: date)] ?? 0
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(heatColor(score))
                            .frame(width: 12, height: 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                            )
                    }
                }
                .padding(.vertical, 4)
            }
            
            HStack(spacing: 8) {
                Text("Less")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                ForEach([0, 25, 50, 75, 100], id: \.self) { score in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatColor(Double(score)))
                        .frame(width: 8, height: 8)
                }
                
                Text("More")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(UIColor.systemGray6).opacity(0.1))
        )
    }
    
    private func heatColor(_ score: Double) -> Color {
        if score == 0 { return Color.white.opacity(0.05) }
        if score < 33 { return Color.red.opacity(0.6) }
        if score < 66 { return Color.yellow.opacity(0.6) }
        return Color.green.opacity(0.7)
    }
}
