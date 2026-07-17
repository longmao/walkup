//
//  AlarmScheduler.swift
//  StepUp — UNUserNotificationCenter-based alarm scheduling
//

import Foundation
import UserNotifications

/// Schedules the recurring local notification that fires the alarm.
enum AlarmScheduler {
    static let alarmIdentifier = "stepup.alarm.fire"

    /// Request notification + motion permission up front. Safe to call multiple times.
    static func requestPermissions() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    /// Schedule (or reschedule) the alarm. Cancels any prior alarm first.
    static func schedule(_ alarm: Alarm) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [alarmIdentifier])

        guard alarm.enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Walk Up"
        content.body = "Walk \(alarm.stepCount) steps to dismiss."
        content.sound = .default
        content.categoryIdentifier = "STEPUP_ALARM"
        content.userInfo = ["stepCount": alarm.stepCount]

        let calendar = Calendar.current
        let comps = calendar.dateComponents([.hour, .minute], from: alarm.time)

        if alarm.repeatDays.isEmpty {
            // One-shot: next occurrence of the given hour:minute
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: DateComponents(hour: comps.hour, minute: comps.minute),
                repeats: false
            )
            let req = UNNotificationRequest(identifier: alarmIdentifier, content: content, trigger: trigger)
            try? await center.add(req)
        } else {
            // Repeating: schedule one per repeat day with weekday component.
            for weekday in alarm.repeatDays.sorted() {
                let dayComp = DateComponents(hour: comps.hour, minute: comps.minute, weekday: weekday)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dayComp, repeats: true)
                let id = "\(alarmIdentifier).\(weekday)"
                let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                try? await center.add(req)
            }
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// CLI smoke-test hook: when launched with `-autotest N`, schedule a
    /// `UNTimeIntervalNotificationTrigger` that fires `N` seconds from now.
    /// This lets us verify willPresent + didReceive end-to-end without driving
    /// the iOS date-picker UI from CI. Production launches (no `-autotest`)
    /// are unaffected.
    static func scheduleAutotest(after seconds: TimeInterval, stepCount: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Walk Up"
        content.body = "Walk \(stepCount) steps to dismiss."
        content.sound = .default
        content.categoryIdentifier = "STEPUP_ALARM"
        content.userInfo = ["stepCount": stepCount]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let req = UNNotificationRequest(identifier: "stepup.autotest", content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(req)
    }
}