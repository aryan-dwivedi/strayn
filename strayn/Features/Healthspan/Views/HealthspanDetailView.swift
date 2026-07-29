//
//  HealthspanDetailView.swift
//  strayn
//
//  Detailed breakdown of Strayn Age components, Pace of Aging drivers,
//  and actionable insights with explanations.
//

import SwiftUI

// MARK: - Healthspan Detail View

struct HealthspanDetailView: View {
    let healthspan: Healthspan
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DetailTab = .age
    
    enum DetailTab: String, CaseIterable {
        case age = "Strayn Age"
        case pace = "Pace"
        case insights = "Insights"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab selector
                    tabSelector
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        straynAgeDetailView
                            .tag(DetailTab.age)
                        
                        paceDetailView
                            .tag(DetailTab.pace)
                        
                        insightsDetailView
                            .tag(DetailTab.insights)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("HEALTHSPAN DETAILS")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.5))
                        
                        Rectangle()
                            .fill(selectedTab == tab ? StraynColors.recovery : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    // MARK: - Strayn Age Detail View
    
    private var straynAgeDetailView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Age summary card
                ageSummaryCard
                
                // Component breakdown
                componentBreakdownSection
                
                // Why this score
                whyThisScoreSection
                
                Spacer().frame(minHeight: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var ageSummaryCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Strayn Age")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", healthspan.straynAge.age))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("years")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Chronological Age")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text(String(format: "%.0f", healthspan.straynAge.chronologicalAge))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack {
                Label {
                    Text(healthspan.straynAge.ageDeltaDescription)
                        .font(.system(size: 14, weight: .semibold))
                } icon: {
                    Image(systemName: healthspan.straynAge.ageDelta < 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                }
                .foregroundColor(healthspan.straynAge.ageDelta < 0 ? StraynColors.recovery : StraynColors.zoneRed)
                
                Spacer()
                
                // Confidence indicator
                HStack(spacing: 4) {
                    Image(systemName: healthspan.straynAge.confidence.iconName)
                        .font(.system(size: 12))
                    Text(healthspan.straynAge.confidence.rawValue + " Confidence")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var componentBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AGE COMPONENTS")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.white.opacity(0.5))
            
            VStack(spacing: 12) {
                AgeComponentCard(component: healthspan.straynAge.cardiovascularAge)
                AgeComponentCard(component: healthspan.straynAge.autonomicAge)
                AgeComponentCard(component: healthspan.straynAge.sleepAge)
                
                if let metabolic = healthspan.straynAge.metabolicAge {
                    AgeComponentCard(component: metabolic)
                }
            }
        }
    }
    
    private var whyThisScoreSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("WHY THIS SCORE?")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.white.opacity(0.4))
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Strayn Age is calculated using a rolling 6-month average of your health metrics across four key systems:")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(3)
                
                VStack(alignment: .leading, spacing: 8) {
                    explanationBullet(icon: "heart.fill", text: "Cardiovascular fitness (RHR, VO₂ Max)")
                    explanationBullet(icon: "waveform.path.ecg", text: "Autonomic health (HRV, Recovery)")
                    explanationBullet(icon: "moon.fill", text: "Sleep quality (Duration, Consistency)")
                    explanationBullet(icon: "figure.run", text: "Metabolic fitness (Activity, Steps)")
                }
                
                Text("Each component is compared to population norms for your age, producing an age delta that represents whether that system is performing younger or older than expected.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .lineSpacing(3)
                    .padding(.top, 8)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }
    
    private func explanationBullet(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(StraynColors.recovery)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // MARK: - Pace Detail View
    
    private var paceDetailView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Pace summary
                paceSummaryCard
                
                // Pillar breakdown
                pillarBreakdownSection
                
                // Primary drivers
                primaryDriversSection
                
                Spacer().frame(minHeight: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var paceSummaryCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pace of Aging")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", healthspan.paceOfAging.pace))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("x")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Zone indicator
                VStack(alignment: .trailing, spacing: 8) {
                    Image(systemName: healthspan.paceOfAging.zone.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(paceZoneColor)
                    
                    Text(healthspan.paceOfAging.zone.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(paceZoneColor)
                }
            }
            
            Text(healthspan.paceOfAging.zone.description)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(3)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Trend
            HStack {
                Label {
                    Text(healthspan.paceOfAging.trend.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                } icon: {
                    Image(systemName: healthspan.paceOfAging.trend.iconName)
                }
                .foregroundColor(trendColor)
                
                Spacer()
                
                Text("Based on last 30 days vs 6-month baseline")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var paceZoneColor: Color {
        switch healthspan.paceOfAging.zone {
        case .optimal, .slow: return StraynColors.recovery
        case .steady: return StraynColors.zoneYellow
        case .elevated, .accelerated: return StraynColors.zoneRed
        }
    }
    
    private var trendColor: Color {
        switch healthspan.paceOfAging.trend {
        case .improving: return StraynColors.recovery
        case .stable: return StraynColors.zoneYellow
        case .worsening: return StraynColors.zoneRed
        }
    }
    
    private var pillarBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PILLAR BREAKDOWN")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.white.opacity(0.5))
            
            VStack(spacing: 12) {
                PillarPaceCard(pillar: healthspan.paceOfAging.sleepPace)
                PillarPaceCard(pillar: healthspan.paceOfAging.activityPace)
                PillarPaceCard(pillar: healthspan.paceOfAging.cardiovascularPace)
                PillarPaceCard(pillar: healthspan.paceOfAging.recoveryPace)
            }
        }
    }
    
    private var primaryDriversSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PRIMARY DRIVERS")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.white.opacity(0.5))
            
            VStack(spacing: 12) {
                ForEach(healthspan.paceOfAging.primaryDrivers) { driver in
                    PaceDriverCard(driver: driver)
                }
            }
        }
    }
    
    // MARK: - Insights Detail View
    
    private var insightsDetailView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Text("Coming Soon")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 100)
                
                Text("Detailed insights and recommendations will appear here.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Age Component Card

struct AgeComponentCard: View {
    let component: StraynAge.AgeComponent
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(component.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Age Impact: \(String(format: "%+.1f", component.ageDelta)) years")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(component.ageDelta < 0 ? StraynColors.recovery : StraynColors.zoneRed)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Text(String(format: "%.1f", component.estimatedAge))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(16)
            
            // Expanded content
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(component.primaryDrivers, id: \.metric) { driver in
                        DriverRow(driver: driver)
                    }
                }
                .padding(16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Driver Row

struct DriverRow: View {
    let driver: StraynAge.AgeComponent.Driver
    
    var body: some View {
        HStack(spacing: 12) {
            // Impact indicator
            Circle()
                .fill(impactColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(driver.metric)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if let value = driver.value {
                        Text(String(format: "%.0f", value))
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Text(driver.explanation)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .lineSpacing(2)
            }
        }
    }
    
    private var impactColor: Color {
        switch driver.impact {
        case .veryPositive, .positive: return StraynColors.recovery
        case .neutral: return StraynColors.zoneYellow
        case .negative, .veryNegative: return StraynColors.zoneRed
        }
    }
}

// MARK: - Pillar Pace Card

struct PillarPaceCard: View {
    let pillar: PaceOfAging.PillarPace
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: pillar.pillar.iconName)
                .font(.system(size: 20))
                .foregroundColor(pillarColor)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(pillarColor.opacity(0.15))
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(pillar.pillar.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(pillar.zone.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(pillarColor)
            }
            
            Spacer()
            
            // Pace value
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1fx", pillar.pace))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if pillar.changeFromBaseline != 0 {
                    Text(String(format: "%+.0f%%", pillar.changeFromBaseline * 100))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(pillar.changeFromBaseline > 0 ? StraynColors.recovery : StraynColors.zoneRed)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var pillarColor: Color {
        switch pillar.zone {
        case .optimal, .slow: return StraynColors.recovery
        case .steady: return StraynColors.zoneYellow
        case .elevated, .accelerated: return StraynColors.zoneRed
        }
    }
}

// MARK: - Pace Driver Card

struct PaceDriverCard: View {
    let driver: PaceOfAging.PaceDriver
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Direction indicator
                Image(systemName: driver.direction == .slowing ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .foregroundColor(driver.direction == .slowing ? StraynColors.recovery : StraynColors.zoneRed)
                
                Text(driver.metric)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Magnitude badge
                Text(driver.magnitude.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
            }
            
            Text(driver.explanation)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(3)
            
            if let actionable = driver.actionableInsight {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10))
                    Text(actionable)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(StraynColors.recovery)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Preview

#Preview {
    HealthspanDetailView(
        healthspan: HealthspanEngine.createMockHealthspan()
    )
}
