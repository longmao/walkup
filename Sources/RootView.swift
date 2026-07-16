//
//  RootView.swift
//  StepUp — top-level view that switches between Setup and Ringing states.
//

import SwiftUI
import UserNotifications

struct RootView: View {
    @EnvironmentObject var alarmStore: AlarmStore
    @EnvironmentObject var stepCounter: StepCounter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// True when the local notification has just fired (handled in-app).
    @State private var isRinging: Bool = false
    /// Steps required for THIS ringing (random per fire = anti-cheat).
    @State private var requiredSteps: Int = 0
    /// Long-press progress for emergency dismiss (fallback per 5.1.1(iv)).
    @State private var emergencyHold: Double = 0

    var body: some View {
        ZStack {
            if isRinging {
                AlarmRingingView(
                    requiredSteps: requiredSteps,
                    currentSteps: stepCounter.currentSteps,
                    emergencyHold: $emergencyHold,
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
        }
        .onReceive(NotificationCenter.default.publisher(for: .stepUpAlarmFired)) { _ in
            startRinging()
        }
    }

    private func requestPermissionsIfNeeded() async {
        _ = await AlarmScheduler.requestPermissions()
        if alarmStore.alarm.enabled {
            await AlarmScheduler.schedule(alarmStore.alarm)
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
        emergencyHold = 0
    }
}

/// Posted by the app's UNUserNotificationCenter delegate when the alarm fires and the app is foregrounded.
extension Notification.Name {
    static let stepUpAlarmFired = Notification.Name("stepUpAlarmFired")
}