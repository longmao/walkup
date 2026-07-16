//
//  Models.swift
//  StepUp — data model + persistent alarm store
//

import Foundation
import SwiftUI

/// User-configurable alarm.
struct Alarm: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    /// Time of day the alarm fires.
    var time: Date
    /// Whether the alarm is armed.
    var enabled: Bool
    /// Number of steps required to dismiss (10-100).
    var stepCount: Int
    /// Repeat days (Sunday = 1 in Calendar, but we use 1-7 = Mon-Sun for clarity).
    var repeatDays: Set<Int>

    static let `default` = Alarm(
        time: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(),
        enabled: false,
        stepCount: 20,
        repeatDays: [1, 2, 3, 4, 5]  // weekdays by default
    )

    static let minSteps = 10
    static let maxSteps = 100

    /// Random steps in valid range, used as anti-cheat: each ringing uses a new value.
    static func randomStepCount(base: Int) -> Int {
        let jitter = Int.random(in: -3...5)
        return max(Self.minSteps, min(Self.maxSteps, base + jitter))
    }
}

/// Persists the current alarm in UserDefaults. Single-alarm app for v1.
@MainActor
final class AlarmStore: ObservableObject {
    @Published var alarm: Alarm {
        didSet { save() }
    }

    private let key = "stepup.alarm.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Alarm.self, from: data) {
            self.alarm = decoded
        } else {
            self.alarm = .default
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(alarm) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    var weekdayLabels: [String] {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    }
}