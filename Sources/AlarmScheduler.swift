//
//  AlarmScheduler.swift
//  StepUp — UNUserNotificationCenter-based alarm scheduling
//

import Foundation
import UIKit
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

        let content = buildContent(stepCount: alarm.stepCount, hourMinute: alarm.time)

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
        let content = buildContent(stepCount: stepCount, hourMinute: nil)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let req = UNNotificationRequest(identifier: "stepup.autotest", content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(req)
    }

    /// Build a notification content that's actually worth reading at 6:30am.
    /// - Title mirrors the in-app sunrise ring state ("Sun's up ✓").
    /// - Subtitle tells the price tag up front — *"Walk N steps."* — so the
    ///   user knows exactly what's about to happen without scrolling.
    /// - Body is poetic and on-brand with onboarding.
    /// - `.timeSensitive` lets the alarm bypass Focus modes (iOS 15+ treats
    ///   alarm-category notifications as time-sensitive for free).
    /// - relevance 1.0 keeps it pinned near the top of the notification
    ///   summary stack.
    /// - threadIdentifier groups repeated weekday fires into a single stack
    ///   row instead of N parallel rows.
    /// - Attachment: lazily-written PNG of the sunrise hero, so when the user
    ///   long-presses the banner they see the same editorial icon that lives
    ///   on the home screen — instead of the default gray app-square.
    private static func buildContent(stepCount: Int, hourMinute: Date?) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Sun's up."
        content.subtitle = "Walk \(stepCount) steps to wake."
        content.body = bodyText(stepCount: stepCount, hourMinute: hourMinute)
        content.sound = .default
        content.categoryIdentifier = "STEPUP_ALARM"
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0
        content.threadIdentifier = "stepup.alarm"
        content.userInfo = ["stepCount": stepCount]

        if let url = notificationHeroURL(),
           let attachment = try? UNNotificationAttachment(
               identifier: "stepup.hero",
               url: url,
               options: [
                   // Don't pre-bake the thumbnail — iOS will downsample at
                   // display time, which keeps the original master crisp.
                   UNNotificationAttachmentOptionsThumbnailTimeKey: NSNumber(value: 1.0)
               ]
           ) {
            content.attachments = [attachment]
        }
        return content
    }

    private static func bodyText(stepCount: Int, hourMinute: Date?) -> String {
        guard let hourMinute else {
            return "Don't snooze. Walk it off."
        }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        let time = f.string(from: hourMinute)
        return "It's \(time). \(stepCount) steps and you're up."
    }

    // MARK: - Notification attachment

    /// Returns a file URL pointing at a 512x512 PNG of the app icon,
    /// rewriting it on first call (cache invalidates when the icon PNG asset
    /// changes). iOS copies the file into the notification's sandbox on
    /// delivery, so this `tmp/` location is fine — it just must exist on
    /// disk at schedule time.
    private static func notificationHeroURL() -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("walkup-notification-hero.png")
        if FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        guard let img = UIImage(named: "AppIcon") else { return nil }
        guard let data = img.pngData() else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}