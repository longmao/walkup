//
//  RootView.swift
//  StepUp — top-level view. Switches between Setup/Ringing/About + a custom
//  bottom floating pill (no default TabView per DESIGN_SPEC §5).
//

import SwiftUI
import UserNotifications
import CoreMotion

struct RootView: View {
    @EnvironmentObject var alarmStore: AlarmStore
    @EnvironmentObject var stepCounter: StepCounter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// True when the local notification has just fired (handled in-app).
    @State private var isRinging: Bool = false
    /// Steps required for THIS ringing (random per fire = anti-cheat).
    @State private var requiredSteps: Int = 0
    /// Which non-ringing screen is on top of the ZStack.
    @State private var selectedTab: Tab = .alarm
    /// First-launch onboarding flag — flips to true and stays persisted.
    @State private var hasOnboarded: Bool = UserDefaults.standard.bool(forKey: "stepup.onboarded.v1")

    enum Tab: Hashable { case alarm, about }

    var body: some View {
        ZStack {
            Color.sky.ignoresSafeArea()

            if isRinging {
                AlarmRingingView(
                    requiredSteps: requiredSteps,
                    currentSteps: stepCounter.currentSteps,
                    onEmergencyDismiss: emergencyDismiss
                )
                .transition(.opacity)
            } else {
                // Background tab content — crossfade when switching.
                ZStack {
                    switch selectedTab {
                    case .alarm:
                        AlarmSetupView(onRingingStarted: startRinging)
                            .transition(.opacity)
                    case .about:
                        AboutView()
                            .transition(.opacity)
                    }
                }
                .animation(reduceMotion ? nil : Motion.spring, value: selectedTab)

                // Bottom floating pill — hidden during ringing.
                VStack {
                    Spacer()
                    BottomPill(selected: $selectedTab)
                        .padding(.bottom, Spacing.xs)
                        .padding(.horizontal, Spacing.l)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                .animation(reduceMotion ? nil : Motion.spring, value: isRinging)
            }
        }
        .animation(reduceMotion ? nil : Motion.spring, value: isRinging)
        .sensoryFeedback(.warning, trigger: stepCounter.currentSteps)
        .task { await bootstrapOnColdStart() }
        .onReceive(NotificationCenter.default.publisher(for: .stepUpAlarmFired)) { _ in
            startRinging()
        }
        .overlay {
            if !hasOnboarded {
                OnboardingView(isPresented: Binding(
                    get: { !hasOnboarded },
                    set: { newValue in hasOnboarded = !newValue }
                ))
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }

    /// Cold-start bootstrap: motion probe + autotest hook.
    ///
    /// IMPORTANT: Notification permission is NOT requested here. Asking on
    /// every cold launch surfaces the system prompt on each app open, which
    /// feels broken. Permission is instead requested once during onboarding
    /// (Step 2 — "Enable motion" — together with the motion prompt, and
    /// again on `OnboardingView.complete()` as a safety net for users who
    /// landed on the alarm-setup screen without finishing onboarding).
    private func bootstrapOnColdStart() async {
        // Proactively trigger the Motion & Fitness permission dialog on
        // first launch if the user hasn't decided yet. Without this, the
        // user can launch the app, glance at the alarm-setup screen, and
        // never see the system permission prompt — which silently breaks
        // step counting. Starting pedometer updates with an empty handler
        // and stopping immediately is enough to surface the system prompt
        // while we ignore any callback noise.
        let status = CMPedometer.authorizationStatus()
        if status == .notDetermined {
            let trigger = CMPedometer()
            trigger.startUpdates(from: Date()) { _, _ in }
            trigger.stopUpdates()
        }

        // If a returning user already enabled alarms but declined notification
        // permission on a prior run, no prompt is needed — but we must still
        // reschedule so today's alarm fires once they tap Enable again from
        // setup. We only act when we know authorization is already granted;
        // otherwise stay quiet and let onboarding drive the prompt.
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
            alarmStore.rescheduleNow()
        }

        // Smoke-test hook: when `AUTOTEST_SECONDS` is set in the launch
        // environment, schedule an alarm that fires `N`s from now so
        // headless verification can exercise willPresent + didReceive
        // without touching the time-picker UI. No-op when the env var
        // is absent.
        if let s = ProcessInfo.processInfo.environment["AUTOTEST_SECONDS"],
           let seconds = Double(s) {
            try? await AlarmScheduler.scheduleAutotest(
                after: seconds,
                stepCount: alarmStore.alarm.stepCount
            )
        }
    }

    private func startRinging() {
        // Anti-cheat: each fire picks a slightly different required-step count.
        requiredSteps = Alarm.randomStepCount(base: alarmStore.alarm.stepCount)
        stepCounter.begin()
        AlarmSound.shared.start()
        isRinging = true
    }

    /// Long-press fallback for users who decline Motion permission (5.1.1(iv) compliance).
    private func emergencyDismiss() {
        stopRinging()
    }

    private func stopRinging() {
        stepCounter.stop()
        AlarmSound.shared.stop()
        isRinging = false
    }
}

/// Posted by the app's UNUserNotificationCenter delegate when the alarm fires and the app is foregrounded.
extension Notification.Name {
    static let stepUpAlarmFired = Notification.Name("stepUpAlarmFired")
}

// MARK: - Bottom floating pill

private struct BottomPill: View {
    @Binding var selected: RootView.Tab

    var body: some View {
        HStack(spacing: Spacing.xs) {
            PillItem(
                label: "Alarm",
                systemImage: "figure.walk.motion",
                isSelected: selected == .alarm
            ) {
                withAnimation(Motion.spring) { selected = .alarm }
            }
            PillItem(
                label: "About",
                systemImage: "info.circle.fill",
                isSelected: selected == .about
            ) {
                withAnimation(Motion.spring) { selected = .about }
            }
        }
        .padding(Spacing.xs)
        .background(
            Capsule().fill(Color.surface.opacity(0.85))
        )
        .overlay(
            Capsule().stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        // Subtle inner glow on the selected half — sunrise tint, no shadow.
        .background(
            Capsule()
                .stroke(Color.sunriseEnd.opacity(0.35), lineWidth: 0.5)
                .blur(radius: 4)
                .padding(-2)
                .opacity(selected == .alarm ? 1 : 0)
        )
    }
}

private struct PillItem: View {
    let label: String
    let systemImage: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? Color.sunriseEnd : Color.textSecondary)
                    .contentTransition(.symbolEffect(.replace))
                if isSelected {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, isSelected ? Spacing.m : Spacing.s)
            .padding(.vertical, Spacing.s)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white.opacity(0.10) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}