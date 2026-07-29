//
//  HapticsManager.swift
//  strayn
//
//  Premium haptic feedback system for the Biological OS experience.
//

import UIKit

class HapticsManager {
    static let shared = HapticsManager()

    // MARK: - Feedback Generators

    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let impactFeedbackSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactFeedbackLight = UIImpactFeedbackGenerator(style: .light)
    private let impactFeedbackMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactFeedbackHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactFeedbackRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // MARK: - State

    private var hapticsEnabled: Bool = true

    init() {
        prepareAllGenerators()
    }

    private func prepareAllGenerators() {
        selectionFeedback.prepare()
        impactFeedbackSoft.prepare()
        impactFeedbackLight.prepare()
        impactFeedbackMedium.prepare()
        impactFeedbackHeavy.prepare()
        impactFeedbackRigid.prepare()
        notificationFeedback.prepare()
    }

    // MARK: - Enable/Disable

    func setHapticsEnabled(_ enabled: Bool) {
        hapticsEnabled = enabled
    }

    // MARK: - Basic Feedback

    func playSelection() {
        guard hapticsEnabled else { return }
        selectionFeedback.selectionChanged()
    }

    func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        switch style {
        case .soft: impactFeedbackSoft.impactOccurred()
        case .light: impactFeedbackLight.impactOccurred()
        case .medium: impactFeedbackMedium.impactOccurred()
        case .heavy: impactFeedbackHeavy.impactOccurred()
        case .rigid: impactFeedbackRigid.impactOccurred()
        @unknown default: impactFeedbackMedium.impactOccurred()
        }
    }

    func playImpactWithIntensity(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat) {
        guard hapticsEnabled else { return }
        switch style {
        case .soft: impactFeedbackSoft.impactOccurred(intensity: intensity)
        case .light: impactFeedbackLight.impactOccurred(intensity: intensity)
        case .medium: impactFeedbackMedium.impactOccurred(intensity: intensity)
        case .heavy: impactFeedbackHeavy.impactOccurred(intensity: intensity)
        case .rigid: impactFeedbackRigid.impactOccurred(intensity: intensity)
        @unknown default: impactFeedbackMedium.impactOccurred(intensity: intensity)
        }
    }

    func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        notificationFeedback.notificationOccurred(type)
    }

    func playSuccess() {
        playNotification(.success)
    }

    func playError() {
        playNotification(.error)
    }

    func playWarning() {
        playNotification(.warning)
    }

    // MARK: - Custom Patterns

    /// Light tap for tab switching
    func playTabSwitch() {
        guard hapticsEnabled else { return }
        impactFeedbackLight.impactOccurred(intensity: 0.5)
    }

    /// Soft feedback for card/metric taps
    func playCardTap() {
        guard hapticsEnabled else { return }
        impactFeedbackSoft.impactOccurred(intensity: 0.7)
    }

    /// Score reveal - escalating intensity pattern
    func playScoreReveal() {
        guard hapticsEnabled else { return }

        // Gentle build-up then satisfying impact
        impactFeedbackLight.impactOccurred(intensity: 0.3)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.impactFeedbackMedium.impactOccurred(intensity: 0.6)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.notificationFeedback.notificationOccurred(.success)
        }
    }

    /// Achievement unlock - celebration pattern
    func playStreakCelebration() {
        guard hapticsEnabled else { return }

        // Triple tap celebration
        impactFeedbackMedium.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.impactFeedbackMedium.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.impactFeedbackHeavy.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.notificationFeedback.notificationOccurred(.success)
        }
    }

    /// Journal completion
    func playJournalComplete() {
        guard hapticsEnabled else { return }

        // Satisfying completion feel
        impactFeedbackMedium.impactOccurred(intensity: 0.8)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.notificationFeedback.notificationOccurred(.success)
        }
    }

    /// Bedtime warning - attention-getting pattern
    func playBedtimeWarning() {
        guard hapticsEnabled else { return }

        // Gentle but noticeable warning
        notificationFeedback.notificationOccurred(.warning)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.impactFeedbackMedium.impactOccurred(intensity: 0.5)
        }
    }

    /// Pull to refresh feedback
    func playPullToRefresh() {
        guard hapticsEnabled else { return }
        impactFeedbackLight.impactOccurred(intensity: 0.6)
    }

    /// Button press - standard button feel
    func playButtonPress() {
        guard hapticsEnabled else { return }
        impactFeedbackMedium.impactOccurred(intensity: 0.8)
    }

    /// Slider tick - for sliders/pickers
    func playSliderTick() {
        guard hapticsEnabled else { return }
        impactFeedbackLight.impactOccurred(intensity: 0.3)
    }

    /// Toggle switch feedback
    func playToggle() {
        guard hapticsEnabled else { return }
        impactFeedbackRigid.impactOccurred(intensity: 0.6)
    }

    /// Long press recognition
    func playLongPressRecognized() {
        guard hapticsEnabled else { return }
        impactFeedbackHeavy.impactOccurred(intensity: 0.7)
    }

    /// Drag start feedback
    func playDragStart() {
        guard hapticsEnabled else { return }
        impactFeedbackMedium.impactOccurred(intensity: 0.5)
    }

    /// Drag end/drop feedback
    func playDrop() {
        guard hapticsEnabled else { return }
        impactFeedbackMedium.impactOccurred(intensity: 0.8)
    }

    /// Number counting tick (for animated numbers)
    func playCountingTick() {
        guard hapticsEnabled else { return }
        impactFeedbackSoft.impactOccurred(intensity: 0.2)
    }

    /// Ring progress completion
    func playRingComplete() {
        guard hapticsEnabled else { return }

        impactFeedbackMedium.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.notificationFeedback.notificationOccurred(.success)
        }
    }

    /// Onboarding step transition
    func playOnboardingStep() {
        guard hapticsEnabled else { return }
        impactFeedbackMedium.impactOccurred(intensity: 0.6)
    }

    /// New badge/achievement unlock
    func playAchievementUnlock() {
        guard hapticsEnabled else { return }

        // Build anticipation then celebrate
        impactFeedbackLight.impactOccurred(intensity: 0.4)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.impactFeedbackMedium.impactOccurred(intensity: 0.7)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.impactFeedbackHeavy.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.notificationFeedback.notificationOccurred(.success)
        }
    }

    /// Navigation back gesture
    func playNavigationPop() {
        guard hapticsEnabled else { return }
        impactFeedbackLight.impactOccurred(intensity: 0.4)
    }

    /// Sheet dismiss
    func playSheetDismiss() {
        guard hapticsEnabled else { return }
        impactFeedbackSoft.impactOccurred(intensity: 0.5)
    }

    /// Sheet present
    func playSheetPresent() {
        guard hapticsEnabled else { return }
        impactFeedbackSoft.impactOccurred(intensity: 0.4)
    }
}
