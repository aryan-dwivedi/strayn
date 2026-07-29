//
//  MorningJournalView.swift
//  strayn
//
//  Gamified morning journal with streaks, progress rings, and celebrations.
//

import SwiftUI

struct MorningJournalView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var habitTracker = HabitTracker.shared

    @State private var currentHabitIndex = 0
    @State private var habits = LoggedHabit.defaults
    @State private var showIntensityPicker = false
    @State private var showNoteInput = false
    @State private var currentNote = ""
    @State private var showMilestone = false
    @State private var milestoneType: MilestoneType = .halfway
    @State private var showConfetti = false
    @State private var cardOffset: CGFloat = 0
    @State private var cardOpacity: Double = 1

    enum MilestoneType {
        case halfway
        case complete
    }

    private var progress: Double {
        Double(currentHabitIndex) / Double(habits.count)
    }

    var body: some View {
        ZStack {
            // Background
            StraynColors.premiumBackgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Main content
                if currentHabitIndex < habits.count {
                    habitCardSection
                } else {
                    completionView
                }
            }

            // Milestone celebration overlay
            if showMilestone {
                milestoneCelebration
            }

            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            HapticsManager.shared.playSheetPresent()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: StraynSpacing.md) {
            HStack {
                // Close button
                Button(action: {
                    HapticsManager.shared.playSheetDismiss()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(StraynColors.surfaceSecondary)
                        )
                }

                Spacer()

                // Streak badge
                if habitTracker.streakInfo.currentStreak > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: habitTracker.streakInfo.isOnFire ? "flame.fill" : "flame")
                            .foregroundColor(habitTracker.streakInfo.isOnFire ? .orange : StraynColors.textSecondary)
                            .symbolEffect(.bounce, value: habitTracker.streakInfo.currentStreak)

                        Text("\(habitTracker.streakInfo.currentStreak)")
                            .font(StraynTypography.labelLarge(.bold))
                            .foregroundColor(habitTracker.streakInfo.isOnFire ? .orange : .white)

                        Text("day streak")
                            .font(StraynTypography.labelSmall())
                            .foregroundColor(StraynColors.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(StraynColors.surfacePrimary)
                    )
                }

                Spacer()

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(StraynColors.surfaceSecondary, lineWidth: 3)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [StraynColors.accentPrimary, StraynColors.zoneGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(), value: progress)

                    Text("\(currentHabitIndex)/\(habits.count)")
                        .font(StraynTypography.labelSmall(.bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
            .padding(.top, StraynSpacing.md)

            // Title
            Text("MORNING JOURNAL")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)
        }
    }

    // MARK: - Habit Card Section

    private var habitCardSection: some View {
        VStack {
            Spacer()

            habitCard(habits[currentHabitIndex])
                .offset(x: cardOffset)
                .opacity(cardOpacity)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            cardOffset = value.translation.width
                        }
                        .onEnded { value in
                            if abs(value.translation.width) > 100 {
                                let isYes = value.translation.width > 0
                                answerHabit(isYes: isYes)
                            } else {
                                withAnimation(.spring()) {
                                    cardOffset = 0
                                }
                            }
                        }
                )

            Spacer()

            // Swipe hint
            HStack(spacing: StraynSpacing.xl) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left")
                    Text("NO")
                }
                .font(StraynTypography.labelSmall())
                .foregroundColor(StraynColors.textMuted)

                Text("Swipe or tap")
                    .font(StraynTypography.labelSmall())
                    .foregroundColor(StraynColors.textTertiary)

                HStack(spacing: 4) {
                    Text("YES")
                    Image(systemName: "arrow.right")
                }
                .font(StraynTypography.labelSmall())
                .foregroundColor(StraynColors.textMuted)
            }
            .padding(.bottom, StraynSpacing.lg)
        }
    }

    // MARK: - Habit Card

    private func habitCard(_ habit: LoggedHabit) -> some View {
        VStack(spacing: StraynSpacing.xl) {
            // Icon with impact-colored ring
            ZStack {
                Circle()
                    .fill(habit.categoryColor.opacity(0.15))
                    .frame(width: 140, height: 140)

                Circle()
                    .stroke(habit.categoryColor.opacity(0.3), lineWidth: 4)
                    .frame(width: 140, height: 140)

                Image(systemName: habit.icon)
                    .font(.system(size: 60))
                    .foregroundColor(habit.categoryColor)
                    .symbolEffect(.bounce, value: currentHabitIndex)
            }

            // Habit info
            VStack(spacing: StraynSpacing.sm) {
                Text(habit.name)
                    .font(StraynTypography.headlineLarge())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                HStack(spacing: 8) {
                    // Category badge
                    Text(habit.category.uppercased())
                        .font(StraynTypography.labelSmall(.semibold))
                        .foregroundColor(habit.categoryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(habit.categoryColor.opacity(0.15))
                        )

                    // Impact badge
                    HStack(spacing: 4) {
                        Image(systemName: habit.impact == .positive ? "arrow.up" : (habit.impact == .negative ? "arrow.down" : "minus"))
                            .font(.system(size: 10, weight: .bold))
                        Text(habit.impact == .positive ? "POSITIVE" : (habit.impact == .negative ? "NEGATIVE" : "NEUTRAL"))
                            .font(StraynTypography.labelSmall(.semibold))
                    }
                    .foregroundColor(habit.impact.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(habit.impact.color.opacity(0.15))
                    )
                }
            }

            // Description
            Text(habit.description)
                .font(StraynTypography.bodySmall)
                .foregroundColor(StraynColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)

            // Question
            Text("Did you do this yesterday?")
                .font(StraynTypography.bodyMedium)
                .foregroundColor(StraynColors.textTertiary)
                .padding(.top, StraynSpacing.md)

            // Answer buttons
            HStack(spacing: StraynSpacing.xl) {
                answerButton(title: "NO", isYes: false, habit: habit)
                answerButton(title: "YES", isYes: true, habit: habit)
            }
            .padding(.top, StraynSpacing.sm)

            // Intensity picker for applicable habits
            if habit.supportsIntensity && habits[currentHabitIndex].wasPerformed {
                intensityPicker(for: habit)
            }

            // Optional note button
            Button(action: {
                HapticsManager.shared.playSelection()
                showNoteInput = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: habits[currentHabitIndex].notes?.isEmpty == false ? "note.text" : "plus")
                        .font(.system(size: 12))
                    Text(habits[currentHabitIndex].notes?.isEmpty == false ? "Edit Note" : "Add Note")
                        .font(StraynTypography.labelSmall())
                }
                .foregroundColor(StraynColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .stroke(StraynColors.borderSubtle, lineWidth: 1)
                )
            }
        }
        .padding(StraynSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: StraynRadius.xxl)
                .fill(StraynColors.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: StraynRadius.xxl)
                .stroke(StraynColors.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, StraynSpacing.lg)
        .sheet(isPresented: $showNoteInput) {
            noteInputSheet
        }
    }

    // MARK: - Answer Button

    private func answerButton(title: String, isYes: Bool, habit: LoggedHabit) -> some View {
        Button(action: {
            answerHabit(isYes: isYes)
        }) {
            Text(title)
                .font(StraynTypography.headlineSmall())
                .foregroundColor(isYes ? .black : .white)
                .frame(width: 100, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: StraynRadius.lg)
                        .fill(isYes ? Color.white : StraynColors.surfaceSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: StraynRadius.lg)
                        .stroke(isYes ? Color.clear : StraynColors.borderSubtle, lineWidth: 1)
                )
        }
        .scaleEffect(cardOffset != 0 ? (isYes ? (cardOffset > 0 ? 1.1 : 0.9) : (cardOffset < 0 ? 1.1 : 0.9)) : 1.0)
        .animation(.spring(response: 0.3), value: cardOffset)
    }

    // MARK: - Intensity Picker

    private func intensityPicker(for habit: LoggedHabit) -> some View {
        VStack(spacing: StraynSpacing.sm) {
            Text("How much?")
                .font(StraynTypography.labelMedium())
                .foregroundColor(StraynColors.textSecondary)

            HStack(spacing: StraynSpacing.sm) {
                ForEach(IntensityLevel.allCases.filter { $0 != .none }, id: \.self) { level in
                    Button(action: {
                        HapticsManager.shared.playSelection()
                        habits[currentHabitIndex].intensity = level
                    }) {
                        Text(level.displayValue)
                            .font(StraynTypography.labelSmall(.semibold))
                            .foregroundColor(habits[currentHabitIndex].intensity == level ? .black : StraynColors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(habits[currentHabitIndex].intensity == level ? Color.white : StraynColors.surfaceSecondary)
                            )
                    }
                }
            }
        }
        .padding(.top, StraynSpacing.md)
    }

    // MARK: - Note Input Sheet

    private var noteInputSheet: some View {
        NavigationView {
            ZStack {
                StraynColors.background.ignoresSafeArea()

                VStack(spacing: StraynSpacing.lg) {
                    Text("Add a note about this habit")
                        .font(StraynTypography.bodyMedium)
                        .foregroundColor(StraynColors.textSecondary)
                        .padding(.top)

                    TextEditor(text: $currentNote)
                        .font(StraynTypography.bodyMedium)
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: StraynRadius.lg)
                                .fill(StraynColors.surfacePrimary)
                        )
                        .frame(height: 150)
                        .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showNoteInput = false
                    }
                    .foregroundColor(StraynColors.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        habits[currentHabitIndex].notes = currentNote
                        showNoteInput = false
                        HapticsManager.shared.playSuccess()
                    }
                    .foregroundColor(StraynColors.accentPrimary)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            currentNote = habits[currentHabitIndex].notes ?? ""
        }
    }

    // MARK: - Answer Handler

    private func answerHabit(isYes: Bool) {
        HapticsManager.shared.playImpact(.medium)
        habits[currentHabitIndex].wasPerformed = isYes

        // Animate out
        withAnimation(.easeInOut(duration: 0.2)) {
            cardOffset = isYes ? 300 : -300
            cardOpacity = 0
        }

        // Check for milestones
        let nextIndex = currentHabitIndex + 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            // Check halfway milestone
            if nextIndex == habits.count / 2 {
                milestoneType = .halfway
                showMilestone = true
                HapticsManager.shared.playCardTap()
            }

            // Move to next
            currentHabitIndex = nextIndex

            // Reset card position
            cardOffset = 0
            cardOpacity = 1

            // Check completion
            if currentHabitIndex >= habits.count {
                showConfetti = true
                HapticsManager.shared.playJournalComplete()

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showConfetti = false
                }
            }
        }
    }

    // MARK: - Milestone Celebration

    private var milestoneCelebration: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showMilestone = false
                    }
                }

            VStack(spacing: StraynSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(StraynColors.accentPrimary.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: milestoneType == .halfway ? "flag.checkered" : "trophy.fill")
                        .font(.system(size: 50))
                        .foregroundColor(StraynColors.accentPrimary)
                        .symbolEffect(.bounce)
                }

                Text(milestoneType == .halfway ? "Halfway There!" : "Almost Done!")
                    .font(StraynTypography.headlineLarge())
                    .foregroundColor(.white)

                Text(milestoneType == .halfway ? "Keep going, you're doing great!" : "Just a few more to complete your journal.")
                    .font(StraynTypography.bodyMedium)
                    .foregroundColor(StraynColors.textSecondary)
                    .multilineTextAlignment(.center)

                Button(action: {
                    HapticsManager.shared.playSelection()
                    withAnimation {
                        showMilestone = false
                    }
                }) {
                    Text("Continue")
                        .font(StraynTypography.labelLarge(.bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(StraynRadius.lg)
                }
            }
            .padding(StraynSpacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.xxl)
                    .fill(StraynColors.surfacePrimary)
            )
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
    }

    // MARK: - Completion View

    private var completionView: some View {
        ScrollView {
            VStack(spacing: StraynSpacing.xxl) {
                Spacer(minLength: 40)

                // Success icon
                ZStack {
                    Circle()
                        .fill(StraynColors.zoneGreen.opacity(0.15))
                        .frame(width: 160, height: 160)

                    Circle()
                        .stroke(StraynColors.zoneGreen.opacity(0.3), lineWidth: 6)
                        .frame(width: 160, height: 160)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 80))
                        .foregroundColor(StraynColors.zoneGreen)
                        .symbolEffect(.bounce)
                }

                // Title and message
                VStack(spacing: StraynSpacing.sm) {
                    Text("Journal Complete!")
                        .font(StraynTypography.displaySmall())
                        .foregroundColor(.white)

                    Text("Your habits are being analyzed for physiological correlations.")
                        .font(StraynTypography.bodyMedium)
                        .foregroundColor(StraynColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Streak update
                streakUpdateCard

                // Summary
                summaryCard

                // Correlation preview
                correlationPreviewCard

                // Save button
                Button(action: saveJournal) {
                    HStack(spacing: 8) {
                        Image(systemName: "icloud.and.arrow.up")
                        Text("SAVE & SYNC")
                    }
                    .font(StraynTypography.labelLarge(.bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(StraynRadius.lg)
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Streak Update Card

    private var streakUpdateCard: some View {
        let newStreak = habitTracker.streakInfo.currentStreak + (habitTracker.hasCompletedJournalToday() ? 0 : 1)

        return VStack(spacing: StraynSpacing.md) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(newStreak) Day Streak")
                        .font(StraynTypography.headlineSmall())
                        .foregroundColor(.white)

                    if newStreak > habitTracker.streakInfo.currentStreak {
                        Text("Streak extended!")
                            .font(StraynTypography.labelSmall())
                            .foregroundColor(StraynColors.zoneGreen)
                    }
                }

                Spacer()

                // Progress to next milestone
                VStack(alignment: .trailing, spacing: 2) {
                    let nextMilestone = [3, 7, 14, 30, 60, 90].first { $0 > newStreak } ?? 100
                    Text("\(nextMilestone - newStreak) to go")
                        .font(StraynTypography.labelSmall())
                        .foregroundColor(StraynColors.textSecondary)

                    Text("\(nextMilestone)-day milestone")
                        .font(StraynTypography.labelSmall())
                        .foregroundColor(StraynColors.textMuted)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(StraynColors.surfaceSecondary)
                        .frame(height: 8)

                    let nextMilestone = [3, 7, 14, 30, 60, 90].first { $0 > newStreak } ?? 100
                    let prevMilestone = [0, 3, 7, 14, 30, 60].last { $0 < nextMilestone } ?? 0
                    let progress = Double(newStreak - prevMilestone) / Double(nextMilestone - prevMilestone)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(StraynSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: StraynRadius.xl)
                .fill(StraynColors.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: StraynRadius.xl)
                .stroke(StraynColors.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        let positiveCount = habits.filter { $0.wasPerformed && $0.impact == .positive }.count
        let negativeAvoided = habits.filter { !$0.wasPerformed && $0.impact == .negative }.count
        let totalPositive = habits.filter { $0.impact == .positive }.count
        let totalNegative = habits.filter { $0.impact == .negative }.count

        return VStack(spacing: StraynSpacing.md) {
            Text("TODAY'S SUMMARY")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)

            HStack(spacing: StraynSpacing.lg) {
                VStack(spacing: 4) {
                    Text("\(positiveCount)/\(totalPositive)")
                        .font(StraynTypography.headlineMedium())
                        .foregroundColor(StraynColors.zoneGreen)
                    Text("Positive habits")
                        .font(StraynTypography.labelSmall())
                        .foregroundColor(StraynColors.textSecondary)
                }

                Rectangle()
                    .fill(StraynColors.borderSubtle)
                    .frame(width: 1, height: 40)

                VStack(spacing: 4) {
                    Text("\(negativeAvoided)/\(totalNegative)")
                        .font(StraynTypography.headlineMedium())
                        .foregroundColor(StraynColors.zoneGreen)
                    Text("Negatives avoided")
                        .font(StraynTypography.labelSmall())
                        .foregroundColor(StraynColors.textSecondary)
                }
            }
        }
        .padding(StraynSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: StraynRadius.xl)
                .fill(StraynColors.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: StraynRadius.xl)
                .stroke(StraynColors.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Correlation Preview Card

    private var correlationPreviewCard: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(StraynColors.accentPrimary)
                Text("CORRELATION PREVIEW")
                    .font(StraynTypography.metricLabel)
                    .tracking(StraynTypography.metricLabelTracking)
                    .foregroundColor(StraynColors.accentPrimary)
            }

            Text("Based on your logged habits, we're calculating how each affects your recovery. Check back after a few days of tracking!")
                .font(StraynTypography.bodySmall)
                .foregroundColor(StraynColors.textSecondary)
                .lineSpacing(4)

            // Mock correlation items
            VStack(spacing: StraynSpacing.sm) {
                correlationRow(icon: "moon.fill", name: "Late Meal", impact: "-12%", isPositive: false)
                correlationRow(icon: "sun.max.fill", name: "Morning Sunlight", impact: "+8%", isPositive: true)
            }
        }
        .padding(StraynSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: StraynRadius.xl)
                .fill(StraynColors.accentPrimary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: StraynRadius.xl)
                .stroke(StraynColors.accentPrimary.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func correlationRow(icon: String, name: String, impact: String, isPositive: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isPositive ? StraynColors.zoneGreen : StraynColors.zoneRed)
                .frame(width: 24)

            Text(name)
                .font(StraynTypography.bodyMedium)
                .foregroundColor(.white)

            Spacer()

            Text(impact)
                .font(StraynTypography.labelMedium(.bold))
                .foregroundColor(isPositive ? StraynColors.zoneGreen : StraynColors.zoneRed)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Save Action

    private func saveJournal() {
        HapticsManager.shared.playSuccess()
        habitTracker.logHabits(habits)

        NotificationCenter.default.post(name: .journalCompleted, object: nil)

        dismiss()
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles()
            }
        }
    }

    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.green, .blue, .orange, .purple, .pink, .yellow]

        particles = (0..<50).map { _ in
            ConfettiParticle(
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                opacity: 1.0,
                velocity: CGPoint(x: CGFloat.random(in: -2...2), y: CGFloat.random(in: 3...8))
            )
        }
    }

    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x
                particles[i].position.y += particles[i].velocity.y
                particles[i].velocity.y += 0.1 // gravity
                particles[i].opacity -= 0.005

                if particles[i].opacity <= 0 {
                    timer.invalidate()
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
    var velocity: CGPoint
}

// MARK: - Preview

#Preview {
    MorningJournalView()
}
