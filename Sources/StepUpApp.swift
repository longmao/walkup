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
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(alarmStore)
                .environmentObject(stepCounter)
        }
    }
}

/// Routes notifications to the in-app ringing flow when the app is in the foreground.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner + play sound even in foreground — this IS the alarm.
        completionHandler([.banner, .sound, .list])
    }
}