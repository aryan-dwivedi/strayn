//
//  HealthspanView.swift
//  strayn
//
//  Main Healthspan view displaying Strayn Age, Pace of Aging,
//  and coaching insights in a WHOOP-inspired design.
//

import SwiftUI

// MARK: - Healthspan View

struct HealthspanView: View {
    @StateObject private var viewModel = HealthspanViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                switch viewModel.displayState {
                case .loading:
                    loadingView
                    
                case .noData:
                    noDataView
                    
                case .locked(let reason):
                    lockedView(reason: reason)
                    
                case .calibrating(let progress, let description):
                    calibratingView(progress: progress, description: description)
                    
                case .active:
                    activeContentView
                    
                case .needsMoreData:
                    needsMoreDataView
                    
                case .hidden:
                    hiddenView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("HEALTHSPAN")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.white)
                        
                        if viewModel.healthspan != nil {
                            Text("Next update in \(viewModel.daysUntilUpdate) days")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadMockData()
        }
    }
    
    // MARK: - Active Content View
    
    private var activeContentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Date range selector
                dateRangeSelector
                
                // Main orb visualization
                if let healthspan = viewModel.healthspan {
                    HealthspanOrbView(
                        straynAge: healthspan.straynAge.age,
                        ageDelta: healthspan.straynAge.ageDelta,
                        chronologicalAge: healthspan.straynAge.chronologicalAge,
                        size: 280
                    )
                    .padding(.vertical, 20)
                }
                
                // Pace of Aging section
                paceOfAgingSection
                
                // Coaching insight card
                coachingInsightCard
                
                // Sleep section header
                if let healthspan = viewModel.healthspan {
                    pillarBreakdownSection(healthspan: healthspan)
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Date Range Selector
    
    private var dateRangeSelector: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text(viewModel.dateRangeText.uppercased())
                .font(.system(size: 13, weight: .semibold))
                .tracking(1)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    // MARK: - Pace of Aging Section
    
    private var paceOfAgingSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("PACE OF AGING")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
            }
            
            HStack(alignment: .center) {
                // Slow indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.healthspan?.paceOfAging.zone == .slow ||
                              viewModel.healthspan?.paceOfAging.zone == .optimal ?
                              StraynColors.recovery : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text("Slow")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Pace value
                Text(viewModel.formattedPaceOfAging)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Fast indicator
                HStack(spacing: 6) {
                    Text("Fast")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(viewModel.healthspan?.paceOfAging.zone == .accelerated ||
                                        viewModel.healthspan?.paceOfAging.zone == .elevated ?
                                        StraynColors.zoneRed : Color.white.opacity(0.3))
                }
            }
            
            // Pace scale
            PaceScaleView(pace: viewModel.healthspan?.paceOfAging.pace ?? 1.0)
                .frame(height: 30)
        }
    }
    
    // MARK: - Coaching Insight Card
    
    private var coachingInsightCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let summary = viewModel.weeklySummary {
                Text(summary.coachingTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                
                Text(summary.coachingMessage)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(3)
                
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Text("VIEW YOUR STRAYN COACH ANALYSIS")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.5)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(StraynColors.recovery)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Pillar Breakdown Section
    
    private func pillarBreakdownSection(healthspan: Healthspan) -> some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Sleep")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Comparison toggles
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 8))
                        Text("6 Month avg.")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrowtriangle.up.fill")
                            .font(.system(size: 8))
                        Text("30 Day avg.")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Sleep consistency row
            ExpandableMetricRow(
                title: "SLEEP CONSISTENCY",
                isExpanded: false
            )
        }
    }
    
    // MARK: - State Views
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Calculating Healthspan...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var noDataView: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Health Data")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("Start tracking your recovery, sleep, and strain to unlock Healthspan insights.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private func lockedView(reason: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Healthspan Locked")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(reason)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Track at least 21 days in a 31-day period to unlock Healthspan.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private func calibratingView(progress: Double, description: String) -> some View {
        VStack(spacing: 24) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(StraynColors.recovery, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Calibrating")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(width: 120, height: 120)
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Your Strayn Age will become more accurate as we gather more data.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var needsMoreDataView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(StraynColors.zoneYellow)
            
            Text("More Data Needed")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("Resume tracking to update your Healthspan. We need at least 21 days of data each month.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var hiddenView: some View {
        VStack(spacing: 24) {
            Image(systemName: "eye.slash")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Healthspan Hidden")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Button(action: { viewModel.toggleHealthspanVisibility() }) {
                Text("Show Healthspan")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(20)
            }
        }
    }
}

// MARK: - Pace Scale View

struct PaceScaleView: View {
    let pace: Double
    
    private let minPace: Double = -1.0
    private let maxPace: Double = 3.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Scale background
                HStack(spacing: 1) {
                    ForEach(0..<40, id: \.self) { index in
                        Rectangle()
                            .fill(colorForIndex(index))
                            .frame(width: geometry.size.width / 42)
                    }
                }
                .frame(height: 12)
                
                // Current position indicator
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 3, height: 20)
                    
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                }
                .offset(x: indicatorOffset(in: geometry.size.width))
                
                // Scale labels
                HStack {
                    Text("-1.0x")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    Text("1.0x")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    Text("3.0x")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.top, 20)
            }
        }
    }
    
    private func colorForIndex(_ index: Int) -> Color {
        let position = Double(index) / 40.0
        if position < 0.4 {
            return StraynColors.recovery.opacity(0.6)
        } else if position < 0.6 {
            return StraynColors.zoneYellow.opacity(0.6)
        } else {
            return StraynColors.zoneRed.opacity(0.6)
        }
    }
    
    private func indicatorOffset(in width: CGFloat) -> CGFloat {
        let normalizedPace = (pace - minPace) / (maxPace - minPace)
        let clampedPace = max(0, min(1, normalizedPace))
        return width * clampedPace - 1.5
    }
}

// MARK: - Expandable Metric Row

struct ExpandableMetricRow: View {
    let title: String
    let isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.vertical, 16)
            
            Divider()
                .background(Color.white.opacity(0.1))
        }
    }
}

// MARK: - Preview

#Preview {
    HealthspanView()
}
