//
//  OnboardingScreenContainer.swift
//  strayn
//
//  Base wrapper for all onboarding screens providing consistent layout and navigation.
//

import SwiftUI

struct OnboardingScreenContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    let showBackButton: Bool
    let showSkipButton: Bool
    let onBack: (() -> Void)?
    let onSkip: (() -> Void)?
    let content: Content

    @State private var titleVisible = false
    @State private var contentVisible = false

    init(
        title: String,
        subtitle: String? = nil,
        showBackButton: Bool = true,
        showSkipButton: Bool = false,
        onBack: (() -> Void)? = nil,
        onSkip: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showBackButton = showBackButton
        self.showSkipButton = showSkipButton
        self.onBack = onBack
        self.onSkip = onSkip
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            navigationBar
                .padding(.top, 8)

            // Title section
            titleSection
                .padding(.top, 32)

            // Content
            content
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            animateEntrance()
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            // Back button
            if showBackButton, let onBack = onBack {
                WHOOPBackButton(action: onBack)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            Spacer()

            // Skip button
            if showSkipButton, let onSkip = onSkip {
                WHOOPSkipButton(action: onSkip)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(titleVisible ? 1 : 0)
                .offset(y: titleVisible ? 0 : 20)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(StraynColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(titleVisible ? 1 : 0)
                    .offset(y: titleVisible ? 0 : 15)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Animation

    private func animateEntrance() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            titleVisible = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
            contentVisible = true
        }
    }
}

// MARK: - Info Screen Container (For intro/processing screens)

struct OnboardingInfoScreen<Content: View>: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    let showSkipButton: Bool
    let onSkip: (() -> Void)?
    let content: Content?

    @State private var iconVisible = false
    @State private var textVisible = false

    init(
        icon: String,
        title: String,
        description: String,
        accentColor: Color = StraynColors.accentPrimary,
        showSkipButton: Bool = false,
        onSkip: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content = { EmptyView() as! Content }
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.accentColor = accentColor
        self.showSkipButton = showSkipButton
        self.onSkip = onSkip
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            if showSkipButton {
                HStack {
                    Spacer()
                    if let onSkip = onSkip {
                        WHOOPSkipButton(action: onSkip)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }

            Spacer()

            // Icon
            ZStack {
                // Glow
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 150, height: 150)
                    .blur(radius: 30)
                    .scaleEffect(iconVisible ? 1.1 : 0.8)

                // Icon circle
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(accentColor)
            }
            .scaleEffect(iconVisible ? 1 : 0.7)
            .opacity(iconVisible ? 1 : 0)

            Spacer().frame(height: 48)

            // Text
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(StraynColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
            }
            .padding(.horizontal, 40)
            .opacity(textVisible ? 1 : 0)
            .offset(y: textVisible ? 0 : 20)

            if let content = content, !(content is EmptyView) {
                content
                    .padding(.top, 32)
                    .opacity(textVisible ? 1 : 0)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            animateEntrance()
        }
    }

    private func animateEntrance() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            iconVisible = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            textVisible = true
        }
    }
}

// MARK: - Result Screen Container

struct OnboardingResultScreen<Content: View>: View {
    let title: String
    let subtitle: String?
    let onContinue: () -> Void
    let content: Content

    @State private var contentVisible = false

    init(
        title: String,
        subtitle: String? = nil,
        onContinue: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onContinue = onContinue
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(StraynColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 60)

            // Content
            ScrollView(showsIndicators: false) {
                content
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
            }
            .opacity(contentVisible ? 1 : 0)

            // Continue button
            WHOOPContinueButton(action: onContinue)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(contentVisible ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                contentVisible = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingScreenContainer(
        title: "How old are you?",
        subtitle: "This helps personalize your recovery insights",
        showBackButton: true,
        onBack: {}
    ) {
        VStack {
            Spacer()

            Text("25")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [StraynColors.accentPrimary, StraynColors.accentPrimary.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Spacer()

            WHOOPContinueButton(action: {})
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
        }
    }
}
