//
//  SettingsView.swift
//  strayn
//
//  iOS Settings-style settings page with premium dark mode styling.
//

import SwiftUI
import PhotosUI
import UIKit
import Combine

// MARK: - Settings View Model

@MainActor
class SettingsViewModel: ObservableObject {
    static let shared = SettingsViewModel()

    // Profile
    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "userName") }
    }
    @Published var membershipTier: String = "Elite Member"
    @Published var profileImage: UIImage?
    @Published var memberSince: Date

    // Haptics
    @Published var hapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled")
            HapticsManager.shared.setHapticsEnabled(hapticsEnabled)
        }
    }

    // Notifications
    @Published var dailyRecoveryReminder: Bool {
        didSet { UserDefaults.standard.set(dailyRecoveryReminder, forKey: "dailyRecoveryReminder") }
    }
    @Published var journalReminder: Bool {
        didSet { UserDefaults.standard.set(journalReminder, forKey: "journalReminder") }
    }
    @Published var journalReminderTime: Date {
        didSet { UserDefaults.standard.set(journalReminderTime, forKey: "journalReminderTime") }
    }
    @Published var achievementNotifications: Bool {
        didSet { UserDefaults.standard.set(achievementNotifications, forKey: "achievementNotifications") }
    }
    @Published var weeklyDigest: Bool {
        didSet { UserDefaults.standard.set(weeklyDigest, forKey: "weeklyDigest") }
    }
    @Published var strainAlerts: Bool {
        didSet { UserDefaults.standard.set(strainAlerts, forKey: "strainAlerts") }
    }

    // Units
    @Published var useMetricUnits: Bool {
        didSet { UserDefaults.standard.set(useMetricUnits, forKey: "useMetricUnits") }
    }
    @Published var temperatureUnit: TemperatureUnit {
        didSet { UserDefaults.standard.set(temperatureUnit.rawValue, forKey: "temperatureUnit") }
    }

    // Data
    @Published var healthKitSyncEnabled: Bool = true
    @Published var lastSyncDate: Date = Date()

    // App Info
    let appVersion: String
    let buildNumber: String

    init() {
        // Load persisted values
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? "Beta User"
        self.memberSince = UserDefaults.standard.object(forKey: "memberSince") as? Date ?? Date()

        self.hapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true

        self.dailyRecoveryReminder = UserDefaults.standard.object(forKey: "dailyRecoveryReminder") as? Bool ?? true
        self.journalReminder = UserDefaults.standard.object(forKey: "journalReminder") as? Bool ?? true
        self.journalReminderTime = UserDefaults.standard.object(forKey: "journalReminderTime") as? Date ?? {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 8
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }()
        self.achievementNotifications = UserDefaults.standard.object(forKey: "achievementNotifications") as? Bool ?? true
        self.weeklyDigest = UserDefaults.standard.object(forKey: "weeklyDigest") as? Bool ?? true
        self.strainAlerts = UserDefaults.standard.object(forKey: "strainAlerts") as? Bool ?? false

        self.useMetricUnits = UserDefaults.standard.object(forKey: "useMetricUnits") as? Bool ?? false
        let tempUnit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? "fahrenheit"
        self.temperatureUnit = TemperatureUnit(rawValue: tempUnit) ?? .fahrenheit

        // App info
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        self.buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        // Load profile image
        loadProfileImage()

        // Apply haptics setting on init
        HapticsManager.shared.setHapticsEnabled(hapticsEnabled)
    }

    func saveProfileImage(_ image: UIImage) {
        profileImage = image
        if let data = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(data, forKey: "profileImageData")
        }
    }

    private func loadProfileImage() {
        if let data = UserDefaults.standard.data(forKey: "profileImageData"),
           let image = UIImage(data: data) {
            profileImage = image
        }
    }

    func exportHealthData() {
        // Trigger export functionality
        HapticsManager.shared.playButtonPress()
    }
}

enum TemperatureUnit: String, CaseIterable {
    case fahrenheit = "fahrenheit"
    case celsius = "celsius"

    var displayName: String {
        switch self {
        case .fahrenheit: return "Fahrenheit"
        case .celsius: return "Celsius"
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel.shared
    @StateObject private var security = SecurityManager.shared
    @StateObject private var deviceUsage = DeviceUsageTracker.shared
    @State private var goal = GoalEngine.shared.selectedGoal
    @State private var showExportSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        List {
            // MARK: - Profile Section
            profileSection

            // MARK: - Goals Section
            goalsSection

            // MARK: - Sleep & Bedtime Section
            sleepSection

            // MARK: - Notifications Section
            notificationsSection

            // MARK: - Feedback Section
            feedbackSection

            // MARK: - Units Section
            unitsSection

            // MARK: - Data & Privacy Section
            dataSection

            // MARK: - About Section
            aboutSection

            // MARK: - Account Section
            accountSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(StraynColors.background)
        .navigationTitle("Settings")
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.saveProfileImage(image)
                }
            }
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        Section {
            HStack(spacing: StraynSpacing.lg) {
                // Profile Photo
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    ZStack {
                        if let image = viewModel.profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [StraynColors.accentPrimary, StraynColors.accentSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Text(String(viewModel.userName.prefix(1)).uppercased())
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }

                        // Edit badge
                        Circle()
                            .fill(StraynColors.surfacePrimary)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(StraynColors.textSecondary)
                            )
                            .offset(x: 24, y: 24)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Name", text: $viewModel.userName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                            .foregroundColor(StraynColors.zoneYellow)
                        Text(viewModel.membershipTier)
                            .font(StraynTypography.labelSmall())
                            .foregroundColor(StraynColors.zoneYellow)
                    }

                    Text("Member since \(viewModel.memberSince, format: .dateTime.month().year())")
                        .font(StraynTypography.labelSmall())
                        .foregroundColor(StraynColors.textMuted)
                }

                Spacer()
            }
            .padding(.vertical, StraynSpacing.sm)
            .listRowBackground(StraynColors.surfacePrimary)
        }
    }

    // MARK: - Goals Section

    private var goalsSection: some View {
        Section {
            Picker("Primary Goal", selection: $goal) {
                ForEach(GoalEngine.shared.availableGoals) { goalOption in
                    HStack {
                        Image(systemName: goalOption.icon)
                        Text(goalOption.title)
                    }
                    .tag(goalOption)
                }
            }
            .onChange(of: goal) { newValue in
                HapticsManager.shared.playSelection()
                GoalEngine.shared.selectedGoal = newValue
            }
            .listRowBackground(StraynColors.surfacePrimary)
        } header: {
            sectionHeader("GOALS")
        } footer: {
            Text("Your primary goal helps strayn personalize insights and recommendations.")
                .font(StraynTypography.labelSmall())
                .foregroundColor(StraynColors.textMuted)
        }
    }

    // MARK: - Sleep Section

    private var sleepSection: some View {
        Section {
            // Bedtime
            HStack {
                Label("Bedtime", systemImage: "moon.fill")
                    .foregroundColor(.white)
                Spacer()
                DatePicker(
                    "",
                    selection: Binding(
                        get: { deviceUsage.configuration.bedtimeDate },
                        set: { newValue in
                            var config = deviceUsage.configuration
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            config.bedtimeHour = components.hour ?? 22
                            config.bedtimeMinute = components.minute ?? 0
                            deviceUsage.configuration = config
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .accentColor(StraynColors.sleep)
            }
            .listRowBackground(StraynColors.surfacePrimary)

            // Wake time
            HStack {
                Label("Wake Time", systemImage: "sunrise.fill")
                    .foregroundColor(.white)
                Spacer()
                DatePicker(
                    "",
                    selection: Binding(
                        get: { deviceUsage.configuration.wakeDate },
                        set: { newValue in
                            var config = deviceUsage.configuration
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            config.wakeHour = components.hour ?? 7
                            config.wakeMinute = components.minute ?? 0
                            deviceUsage.configuration = config
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .accentColor(StraynColors.zoneYellow)
            }
            .listRowBackground(StraynColors.surfacePrimary)

            // Device usage warnings toggle
            Toggle(isOn: Binding(
                get: { deviceUsage.configuration.isEnabled },
                set: { newValue in
                    HapticsManager.shared.playToggle()
                    var config = deviceUsage.configuration
                    config.isEnabled = newValue
                    deviceUsage.configuration = config
                }
            )) {
                Label("Device Usage Warnings", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
            }
            .tint(StraynColors.accentPrimary)
            .listRowBackground(StraynColors.surfacePrimary)

            if deviceUsage.configuration.isEnabled {
                // Warning threshold
                HStack {
                    Label("Warning After", systemImage: "timer")
                        .foregroundColor(.white)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { deviceUsage.configuration.warningThresholdMinutes },
                        set: { newValue in
                            var config = deviceUsage.configuration
                            config.warningThresholdMinutes = newValue
                            deviceUsage.configuration = config
                        }
                    )) {
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                    }
                    .pickerStyle(.menu)
                    .accentColor(StraynColors.textSecondary)
                }
                .listRowBackground(StraynColors.surfacePrimary)

                // In-app warnings
                Toggle(isOn: Binding(
                    get: { deviceUsage.configuration.showInAppWarnings },
                    set: { newValue in
                        HapticsManager.shared.playToggle()
                        var config = deviceUsage.configuration
                        config.showInAppWarnings = newValue
                        deviceUsage.configuration = config
                    }
                )) {
                    Text("In-App Banner")
                        .foregroundColor(.white)
                }
                .tint(StraynColors.accentPrimary)
                .listRowBackground(StraynColors.surfacePrimary)

                // Push notifications
                Toggle(isOn: Binding(
                    get: { deviceUsage.configuration.sendNotifications },
                    set: { newValue in
                        HapticsManager.shared.playToggle()
                        var config = deviceUsage.configuration
                        config.sendNotifications = newValue
                        deviceUsage.configuration = config
                    }
                )) {
                    Text("Push Notifications")
                        .foregroundColor(.white)
                }
                .tint(StraynColors.accentPrimary)
                .listRowBackground(StraynColors.surfacePrimary)
            }
        } header: {
            sectionHeader("SLEEP & BEDTIME")
        } footer: {
            Text("strayn will alert you when using your device during your bedtime window. Blue light exposure before sleep can reduce sleep quality.")
                .font(StraynTypography.labelSmall())
                .foregroundColor(StraynColors.textMuted)
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $viewModel.dailyRecoveryReminder) {
                Label("Daily Recovery Summary", systemImage: "heart.text.square.fill")
                    .foregroundColor(.white)
            }
            .tint(StraynColors.accentPrimary)
            .onChange(of: viewModel.dailyRecoveryReminder) { _ in
                HapticsManager.shared.playToggle()
            }
            .listRowBackground(StraynColors.surfacePrimary)

            Toggle(isOn: $viewModel.journalReminder) {
                Label("Morning Journal Reminder", systemImage: "book.fill")
                    .foregroundColor(.white)
            }
            .tint(StraynColors.accentPrimary)
            .onChange(of: viewModel.journalReminder) { _ in
                HapticsManager.shared.playToggle()
            }
            .listRowBackground(StraynColors.surfacePrimary)

            if viewModel.journalReminder {
                HStack {
                    Text("Reminder Time")
                        .foregroundColor(.white)
                    Spacer()
                    DatePicker(
                        "",
                        selection: $viewModel.journalReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .accentColor(StraynColors.accentPrimary)
                }
                .listRowBackground(StraynColors.surfacePrimary)
            }

            Toggle(isOn: $viewModel.achievementNotifications) {
                Label("Achievement Unlocks", systemImage: "trophy.fill")
                    .foregroundColor(.white)
            }
            .tint(StraynColors.accentPrimary)
            .onChange(of: viewModel.achievementNotifications) { _ in
                HapticsManager.shared.playToggle()
            }
            .listRowBackground(StraynColors.surfacePrimary)

            Toggle(isOn: $viewModel.weeklyDigest) {
                Label("Weekly Performance Digest", systemImage: "chart.bar.fill")
                    .foregroundColor(.white)
            }
            .tint(StraynColors.accentPrimary)
            .onChange(of: viewModel.weeklyDigest) { _ in
                HapticsManager.shared.playToggle()
            }
            .listRowBackground(StraynColors.surfacePrimary)

            Toggle(isOn: $viewModel.strainAlerts) {
                Label("High Strain Alerts", systemImage: "flame.fill")
                    .foregroundColor(.white)
            }
            .tint(StraynColors.accentPrimary)
            .onChange(of: viewModel.strainAlerts) { _ in
                HapticsManager.shared.playToggle()
            }
            .listRowBackground(StraynColors.surfacePrimary)
        } header: {
            sectionHeader("NOTIFICATIONS")
        } footer: {
            Text("Control which notifications you receive from strayn.")
                .font(StraynTypography.labelSmall())
                .foregroundColor(StraynColors.textMuted)
        }
    }

    // MARK: - Feedback Section

    private var feedbackSection: some View {
        Section {
            Toggle(isOn: $viewModel.hapticsEnabled) {
                HStack {
                    Label("Haptic Feedback", systemImage: "waveform")
                        .foregroundColor(.white)
                }
            }
            .tint(StraynColors.accentPrimary)
            .onChange(of: viewModel.hapticsEnabled) { newValue in
                if newValue {
                    HapticsManager.shared.playToggle()
                }
            }
            .listRowBackground(StraynColors.surfacePrimary)

            Toggle("Use Face ID", isOn: $security.useBiometrics)
                .tint(StraynColors.accentPrimary)
                .onChange(of: security.useBiometrics) { _ in
                    HapticsManager.shared.playToggle()
                }
                .listRowBackground(StraynColors.surfacePrimary)
        } header: {
            sectionHeader("EXPERIENCE")
        } footer: {
            Text("Haptic feedback provides tactile responses throughout the app for a more immersive experience.")
                .font(StraynTypography.labelSmall())
                .foregroundColor(StraynColors.textMuted)
        }
    }

    // MARK: - Units Section

    private var unitsSection: some View {
        Section {
            Toggle(isOn: $viewModel.useMetricUnits) {
                Label("Metric Units", systemImage: "ruler")
                    .foregroundColor(.white)
            }
            .tint(StraynColors.accentPrimary)
            .onChange(of: viewModel.useMetricUnits) { _ in
                HapticsManager.shared.playToggle()
            }
            .listRowBackground(StraynColors.surfacePrimary)

            Picker(selection: $viewModel.temperatureUnit) {
                ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                    Text(unit.displayName).tag(unit)
                }
            } label: {
                Label("Temperature", systemImage: "thermometer.medium")
                    .foregroundColor(.white)
            }
            .onChange(of: viewModel.temperatureUnit) { _ in
                HapticsManager.shared.playSelection()
            }
            .listRowBackground(StraynColors.surfacePrimary)
        } header: {
            sectionHeader("UNITS")
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        Section {
            NavigationLink {
                HealthKitSourcesView()
            } label: {
                Label("HealthKit Sources", systemImage: "heart.circle.fill")
                    .foregroundColor(.white)
            }
            .listRowBackground(StraynColors.surfacePrimary)

            Button {
                HapticsManager.shared.playButtonPress()
                showExportSheet = true
            } label: {
                HStack {
                    Label("Export Health Report", systemImage: "square.and.arrow.up")
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(StraynColors.textMuted)
                }
            }
            .listRowBackground(StraynColors.surfacePrimary)
            .sheet(isPresented: $showExportSheet) {
                ExportOptionsSheet()
            }

            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
                    .foregroundColor(.white)
            }
            .listRowBackground(StraynColors.surfacePrimary)

            NavigationLink {
                DataManagementView()
            } label: {
                Label("Manage My Data", systemImage: "externaldrive.fill")
                    .foregroundColor(.white)
            }
            .listRowBackground(StraynColors.surfacePrimary)
        } header: {
            sectionHeader("DATA & PRIVACY")
        } footer: {
            Text("Your health data is stored securely on your device and synced with iCloud if enabled.")
                .font(StraynTypography.labelSmall())
                .foregroundColor(StraynColors.textMuted)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Label("Version", systemImage: "info.circle")
                    .foregroundColor(.white)
                Spacer()
                Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                    .foregroundColor(StraynColors.textSecondary)
            }
            .listRowBackground(StraynColors.surfacePrimary)

            NavigationLink {
                WhatsNewView()
            } label: {
                Label("What's New", systemImage: "sparkles")
                    .foregroundColor(.white)
            }
            .listRowBackground(StraynColors.surfacePrimary)

            Link(destination: URL(string: "https://strayn.app/support")!) {
                HStack {
                    Label("Help & Support", systemImage: "questionmark.circle")
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(StraynColors.textMuted)
                }
            }
            .listRowBackground(StraynColors.surfacePrimary)

            Link(destination: URL(string: "https://strayn.app/feedback")!) {
                HStack {
                    Label("Send Feedback", systemImage: "envelope")
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(StraynColors.textMuted)
                }
            }
            .listRowBackground(StraynColors.surfacePrimary)

            NavigationLink {
                AcknowledgementsView()
            } label: {
                Label("Acknowledgements", systemImage: "heart.fill")
                    .foregroundColor(.white)
            }
            .listRowBackground(StraynColors.surfacePrimary)
        } header: {
            sectionHeader("ABOUT")
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section {
            Button {
                HapticsManager.shared.playButtonPress()
                // Sign out action
            } label: {
                HStack {
                    Spacer()
                    Text("Sign Out")
                        .foregroundColor(StraynColors.accentPrimary)
                    Spacer()
                }
            }
            .listRowBackground(StraynColors.surfacePrimary)

            Button {
                HapticsManager.shared.playWarning()
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Text("Delete Account")
                        .foregroundColor(StraynColors.zoneRed)
                    Spacer()
                }
            }
            .listRowBackground(StraynColors.surfacePrimary)
            .confirmationDialog(
                "Delete Account",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    // Delete account action
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        } header: {
            sectionHeader("ACCOUNT")
        } footer: {
            VStack(spacing: StraynSpacing.md) {
                Text("Made with ❤️ for a healthier life")
                    .font(StraynTypography.labelSmall())
                    .foregroundColor(StraynColors.textMuted)

                Text("© 2024 strayn. All rights reserved.")
                    .font(StraynTypography.labelSmall())
                    .foregroundColor(StraynColors.textMuted.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, StraynSpacing.xl)
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(StraynTypography.metricLabel)
            .tracking(StraynTypography.metricLabelTracking)
            .foregroundColor(StraynColors.textSecondary)
    }
}

// MARK: - Supporting Views

struct HealthKitSourcesView: View {
    var body: some View {
        List {
            Section {
                HealthSourceRow(name: "Apple Watch", icon: "applewatch", isConnected: true)
                HealthSourceRow(name: "iPhone Health", icon: "iphone", isConnected: true)
                HealthSourceRow(name: "Oura Ring", icon: "circle.circle", isConnected: false)
                HealthSourceRow(name: "Whoop", icon: "waveform.path", isConnected: false)
            } footer: {
                Text("Connect additional devices through the Apple Health app to sync more data with strayn.")
                    .font(StraynTypography.labelSmall())
                    .foregroundColor(StraynColors.textMuted)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(StraynColors.background)
        .navigationTitle("HealthKit Sources")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HealthSourceRow: View {
    let name: String
    let icon: String
    let isConnected: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isConnected ? StraynColors.accentPrimary : StraynColors.textMuted)
                .frame(width: 32)

            Text(name)
                .foregroundColor(.white)

            Spacer()

            if isConnected {
                HStack(spacing: 4) {
                    Circle()
                        .fill(StraynColors.zoneGreen)
                        .frame(width: 8, height: 8)
                    Text("Connected")
                        .font(StraynTypography.labelSmall())
                        .foregroundColor(StraynColors.zoneGreen)
                }
            } else {
                Text("Not Connected")
                    .font(StraynTypography.labelSmall())
                    .foregroundColor(StraynColors.textMuted)
            }
        }
        .listRowBackground(StraynColors.surfacePrimary)
    }
}

struct ExportOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var dateRange: ExportDateRange = .lastMonth
    @State private var isExporting = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .listRowBackground(StraynColors.surfacePrimary)

                    Picker("Date Range", selection: $dateRange) {
                        ForEach(ExportDateRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .listRowBackground(StraynColors.surfacePrimary)
                } header: {
                    Text("EXPORT OPTIONS")
                        .font(StraynTypography.metricLabel)
                        .tracking(StraynTypography.metricLabelTracking)
                        .foregroundColor(StraynColors.textSecondary)
                }

                Section {
                    Button {
                        isExporting = true
                        HapticsManager.shared.playButtonPress()
                        // Export action
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isExporting = false
                            HapticsManager.shared.playSuccess()
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Export Data")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(StraynColors.accentPrimary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(StraynColors.background)
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

enum ExportFormat: String, CaseIterable {
    case pdf, csv, json

    var displayName: String {
        rawValue.uppercased()
    }
}

enum ExportDateRange: String, CaseIterable {
    case lastWeek, lastMonth, last3Months, lastYear, allTime

    var displayName: String {
        switch self {
        case .lastWeek: return "Last Week"
        case .lastMonth: return "Last Month"
        case .last3Months: return "Last 3 Months"
        case .lastYear: return "Last Year"
        case .allTime: return "All Time"
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StraynSpacing.lg) {
                Text("Privacy Policy")
                    .font(StraynTypography.headlineLarge())
                    .foregroundColor(.white)

                Text("Last updated: January 2024")
                    .font(StraynTypography.labelSmall())
                    .foregroundColor(StraynColors.textMuted)

                privacySection("Data Collection", content: "strayn collects health metrics from Apple HealthKit including heart rate, HRV, sleep data, and activity information. This data is used solely to provide personalized health insights.")

                privacySection("Data Storage", content: "All health data is stored securely on your device and optionally synced via iCloud. We do not store your health data on our servers.")

                privacySection("Third Parties", content: "We do not sell, share, or transfer your personal health data to third parties for advertising or marketing purposes.")

                privacySection("Your Rights", content: "You can export or delete all your data at any time through the Settings menu. Deleting your account will permanently remove all associated data.")
            }
            .padding()
        }
        .background(StraynColors.background)
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func privacySection(_ title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: StraynSpacing.sm) {
            Text(title)
                .font(StraynTypography.headlineSmall())
                .foregroundColor(.white)

            Text(content)
                .font(StraynTypography.bodyMedium)
                .foregroundColor(StraynColors.textSecondary)
                .lineSpacing(4)
        }
        .padding(.top, StraynSpacing.md)
    }
}

struct DataManagementView: View {
    @State private var showDeleteAllConfirmation = false

    var body: some View {
        List {
            Section {
                Button {
                    // Clear cache
                    HapticsManager.shared.playButtonPress()
                } label: {
                    Label("Clear Cache", systemImage: "trash")
                        .foregroundColor(.white)
                }
                .listRowBackground(StraynColors.surfacePrimary)

                Button {
                    // Reset preferences
                    HapticsManager.shared.playButtonPress()
                } label: {
                    Label("Reset Preferences", systemImage: "arrow.counterclockwise")
                        .foregroundColor(.white)
                }
                .listRowBackground(StraynColors.surfacePrimary)
            } header: {
                Text("CACHE & PREFERENCES")
                    .font(StraynTypography.metricLabel)
                    .tracking(StraynTypography.metricLabelTracking)
                    .foregroundColor(StraynColors.textSecondary)
            }

            Section {
                Button {
                    HapticsManager.shared.playWarning()
                    showDeleteAllConfirmation = true
                } label: {
                    Label("Delete All Data", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(StraynColors.zoneRed)
                }
                .listRowBackground(StraynColors.surfacePrimary)
                .confirmationDialog(
                    "Delete All Data",
                    isPresented: $showDeleteAllConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete Everything", role: .destructive) {
                        // Delete all action
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will delete all your health data, preferences, and achievements. This action cannot be undone.")
                }
            } header: {
                Text("DANGER ZONE")
                    .font(StraynTypography.metricLabel)
                    .tracking(StraynTypography.metricLabelTracking)
                    .foregroundColor(StraynColors.zoneRed)
            } footer: {
                Text("Deleting your data is permanent and cannot be recovered.")
                    .font(StraynTypography.labelSmall())
                    .foregroundColor(StraynColors.textMuted)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(StraynColors.background)
        .navigationTitle("Manage Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WhatsNewView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StraynSpacing.xl) {
                // Version header
                VStack(alignment: .leading, spacing: StraynSpacing.sm) {
                    Text("Version 1.0")
                        .font(StraynTypography.headlineLarge())
                        .foregroundColor(.white)

                    Text("January 2024")
                        .font(StraynTypography.labelMedium())
                        .foregroundColor(StraynColors.textMuted)
                }

                // Features
                WhatsNewFeature(
                    icon: "waveform.path.ecg",
                    iconColor: StraynColors.recovery,
                    title: "Biological Age Tracking",
                    description: "See your biological age based on key health metrics and track improvements over time."
                )

                WhatsNewFeature(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: StraynColors.strain,
                    title: "AI-Powered Insights",
                    description: "Get personalized recommendations based on your recovery, strain, and sleep patterns."
                )

                WhatsNewFeature(
                    icon: "moon.stars.fill",
                    iconColor: StraynColors.sleep,
                    title: "Sleep Hygiene Tracking",
                    description: "Track device usage before bed and receive gentle reminders to improve sleep quality."
                )

                WhatsNewFeature(
                    icon: "trophy.fill",
                    iconColor: StraynColors.zoneYellow,
                    title: "40+ Achievements",
                    description: "Unlock achievements as you build healthy habits and reach new milestones."
                )

                WhatsNewFeature(
                    icon: "sparkles",
                    iconColor: StraynColors.accentPrimary,
                    title: "Premium Design",
                    description: "Beautiful glassmorphic UI with smooth animations and haptic feedback."
                )
            }
            .padding()
        }
        .background(StraynColors.background)
        .navigationTitle("What's New")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WhatsNewFeature: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: StraynSpacing.md) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(StraynTypography.headlineSmall())
                    .foregroundColor(.white)

                Text(description)
                    .font(StraynTypography.bodySmall)
                    .foregroundColor(StraynColors.textSecondary)
                    .lineSpacing(4)
            }
        }
    }
}

struct AcknowledgementsView: View {
    var body: some View {
        List {
            Section {
                AcknowledgementRow(name: "Apple HealthKit", description: "Health data integration")
                AcknowledgementRow(name: "Swift Charts", description: "Data visualization")
                AcknowledgementRow(name: "SwiftUI", description: "User interface framework")
            } header: {
                Text("FRAMEWORKS")
                    .font(StraynTypography.metricLabel)
                    .tracking(StraynTypography.metricLabelTracking)
                    .foregroundColor(StraynColors.textSecondary)
            }

            Section {
                AcknowledgementRow(name: "SF Symbols", description: "Icon library by Apple")
            } header: {
                Text("DESIGN")
                    .font(StraynTypography.metricLabel)
                    .tracking(StraynTypography.metricLabelTracking)
                    .foregroundColor(StraynColors.textSecondary)
            }

            Section {
                Text("Special thanks to everyone who provided feedback during beta testing.")
                    .font(StraynTypography.bodySmall)
                    .foregroundColor(StraynColors.textSecondary)
                    .listRowBackground(StraynColors.surfacePrimary)
            } header: {
                Text("BETA TESTERS")
                    .font(StraynTypography.metricLabel)
                    .tracking(StraynTypography.metricLabelTracking)
                    .foregroundColor(StraynColors.textSecondary)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(StraynColors.background)
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AcknowledgementRow: View {
    let name: String
    let description: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .foregroundColor(.white)
                Text(description)
                    .font(StraynTypography.labelSmall())
                    .foregroundColor(StraynColors.textMuted)
            }
            Spacer()
        }
        .listRowBackground(StraynColors.surfacePrimary)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
    .preferredColorScheme(.dark)
}
