//
//  StepUpApp.swift
//  StepUp — Walk to dismiss the alarm. Free forever.
//

import SwiftUI
import UserNotifications

@main
struct StepUpApp: App {
    @StateObject private var alarmStore = AlarmStore()
    @StateObject private var stepCounter = StepCounter()

    init() {
        // Set the notification delegate so alarms can present even when app is foregrounded.
        let center = UNUserNotificationCenter.current()
        center.delegate = NotificationDelegate.shared
        center.setNotificationCategories(NotificationDelegate.categories)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(alarmStore)
                .environmentObject(stepCounter)
                // Smoke-test entry: `walkup://test-fire` bypasses the
                // UNNotificationCenter permission gate and posts the in-app
                // "alarm fired" notification directly. This exercises the
                // RootView.onReceive → AlarmRingingView path on devices where
                // we can't programmatically grant notification permission
                // (the full path through willPresent/didReceive also fires
                // the same notification, so a green `walkup://test-fire`
                // plus a green UN-fire in production imply the full flow).
                .onOpenURL { url in
                    if url.scheme == "walkup", url.host == "test-fire" {
                        NotificationCenter.default.post(name: .stepUpAlarmFired, object: nil)
                    }
                }
        }
    }
}

/// Routes notifications to the in-app ringing flow in both foreground and background paths.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    /// Register the alarm category so didReceive fires when the user taps the
    /// system banner, even when the app was launched from a terminated state.
    static let categories: Set<UNNotificationCategory> = {
        let dismiss = UNNotificationAction(
            identifier: "STEPUP_DISMISS",
            title: "I'm awake",
            options: [.foreground]
        )
        return [UNNotificationCategory(
            identifier: "STEPUP_ALARM",
            actions: [dismiss],
            intentIdentifiers: [],
            options: []
        )]
    }()

    /// Foreground path: user already has the app open when the alarm fires.
    /// We MUST post the in-app notification here, otherwise the ringing view
    /// never appears — willPresent alone only controls banner + sound.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        NotificationCenter.default.post(name: .stepUpAlarmFired, object: nil)
        completionHandler([.banner, .sound, .list])
    }

    /// Background / terminated path: the user tapped the system banner (or a
    /// category action) which launched or foregrounded the app. Route into the
    /// same ringing flow as the foreground path.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let request = response.notification.request
        if request.content.categoryIdentifier == "STEPUP_ALARM" {
            NotificationCenter.default.post(name: .stepUpAlarmFired, object: nil)
        }
        completionHandler()
    }
}