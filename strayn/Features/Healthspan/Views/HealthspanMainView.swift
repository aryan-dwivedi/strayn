//
//  HealthspanMainView.swift
//  strayn
//
//  WHOOP-inspired Healthspan view with organic blob orb,
//  weekly navigation, and -1x to 3x pace of aging scale.
//

import SwiftUI

// MARK: - Healthspan Main View

struct HealthspanMainView: View {
    @StateObject private var viewModel = HealthspanViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showDetailView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Pure black background
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
                    mainContentView
                    
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
                        
                        Text("Next update in \(viewModel.daysUntilUpdate) \(viewModel.daysUntilUpdate == 1 ? "day" : "days")")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showDetailView = true }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .sheet(isPresented: $showDetailView) {
                if let healthspan = viewModel.healthspan {
                    HealthspanDetailView(healthspan: healthspan)
                }
            }
        }
        .onAppear {
            viewModel.loadMockData()
        }
    }
    
    // MARK: - Main Content
    
    private var mainContentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Week navigation
                weekNavigator
                
                // Main orb visualization
                orbVisualization
                    .padding(.vertical, 16)
                
                // Pace of Aging section
                paceOfAgingSection
                
                // Coaching insight card
                coachingInsightCard
                
                // Sleep metrics section
                if let healthspan = viewModel.healthspan {
                    metricsSection(healthspan: healthspan)
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Week Navigator
    
    private var weekNavigator: some View {
        HStack(spacing: 16) {
            Button(action: { viewModel.goToPreviousWeek() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(viewModel.canGoToPreviousWeek ? .white : .white.opacity(0.3))
            }
            .disabled(!viewModel.canGoToPreviousWeek)
            
            Text(viewModel.currentWeekRangeText.uppercased())
                .font(.system(size: 13, weight: .semibold))
                .tracking(1)
                .foregroundColor(.white.opacity(0.8))
            
            Button(action: { viewModel.goToNextWeek() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(viewModel.canGoToNextWeek ? .white : .white.opacity(0.3))
            }
            .disabled(!viewModel.canGoToNextWeek)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Orb Visualization
    
    private var orbVisualization: some View {
        WHOOPStyleOrbView(
            age: viewModel.displayedStraynAge,
            ageDelta: viewModel.displayedAgeDelta,
            size: 300
        )
    }
    
    // MARK: - Pace of Aging Section
    
    private var paceOfAgingSection: some View {
        WHOOPPaceScaleView(
            currentPace: viewModel.displayedPace,
            isSlowPace: viewModel.isSlowPace
        )
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
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(action: { showDetailView = true }) {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            // Notch indicator at top center
            Triangle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 16, height: 8)
                .offset(y: -4),
            alignment: .top
        )
    }
    
    // MARK: - Metrics Section
    
    private func metricsSection(healthspan: Healthspan) -> some View {
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
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrowtriangle.up.fill")
                            .font(.system(size: 8))
                        Text("30 Day avg.")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Sleep Consistency
            MetricRowView(
                title: "SLEEP CONSISTENCY",
                isExpanded: false
            )
        }
        .padding(.top, 8)
    }
    
    // MARK: - State Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            
            Text("Loading Healthspan...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private var noDataView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.circle")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Data Available")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text("Wear your device for at least 2 weeks to see your Healthspan data.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private func lockedView(reason: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.circle")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Healthspan Locked")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(reason)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private func calibratingView(progress: Double, description: String) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(StraynColors.recovery, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("Calibrating")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var needsMoreDataView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("More Data Needed")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text("Continue wearing your device to generate more Healthspan insights.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var hiddenView: some View {
        VStack(spacing: 20) {
            Image(systemName: "eye.slash")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Healthspan Hidden")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Button("Show Healthspan") {
                viewModel.isHealthspanHidden = false
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(StraynColors.recovery)
        }
    }
}

// MARK: - Triangle Shape for Notch

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Metric Row View

struct MetricRowView: View {
    let title: String
    let isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.vertical, 16)
            
            Divider()
                .background(Color.white.opacity(0.1))
        }
    }
}

// MARK: - Preview

#Preview {
    HealthspanMainView()
}
