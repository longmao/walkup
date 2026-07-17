//
//  RootView.swift
//  StepUp — top-level view that switches between Setup and Ringing states.
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

    var body: some View {
        ZStack {
            if isRinging {
                AlarmRingingView(
                    requiredSteps: requiredSteps,
                    currentSteps: stepCounter.currentSteps,
                    onEmergencyDismiss: emergencyDismiss
                )
                .transition(.opacity)
            } else {
                TabView {
                    AlarmSetupView(onRingingStarted: startRinging)
                        .tabItem { Label("Alarm", systemImage: "alarm.fill") }
                    AboutView()
                        .tabItem { Label("About", systemImage: "info.circle") }
                }
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: isRinging)
        .sensoryFeedback(.warning, trigger: stepCounter.currentSteps)
        .task {
            await requestPermissionsIfNeeded()

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
        .onReceive(NotificationCenter.default.publisher(for: .stepUpAlarmFired)) { _ in
            startRinging()
        }
    }

    private func requestPermissionsIfNeeded() async {
        let granted = await AlarmScheduler.requestPermissions()
        guard granted else { return }
        // Permission just flipped from .notDetermined → authorized; reschedule
        // so a previously-suspended alarm request now actually fires.
        alarmStore.rescheduleNow()
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