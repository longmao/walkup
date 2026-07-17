//
//  AlarmSetupView.swift
//  StepUp — main screen (DESIGN_SPEC §3 S1).
//  No Form / Section / Stepper / Toggle. Free composition on dark sky.
//

import SwiftUI

struct AlarmSetupView: View {
    @EnvironmentObject var alarmStore: AlarmStore
    var onRingingStarted: () -> Void

    /// Step preset chips. Anti-cheat jitter is applied per-fire inside RootView.
    private let stepPresets: [Int] = [10, 25, 50, 100]

    private var timeBinding: Binding<Date> {
        Binding(
            get: { alarmStore.alarm.time },
            set: { alarmStore.alarm.time = $0 }
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    // Top breathing room.
                    Color.clear.frame(height: 8)

                    // ── Time hero ────────────────────────────────────────────────
                    VStack(spacing: Spacing.xs) {
                        DatePicker(
                            "Wake up at",
                            selection: timeBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .accessibilityLabel("Set wake up time")

                        Text(wakeSubtitle)
                            .heroSubtitle()
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }

                    // ── Steps card ───────────────────────────────────────────────
                    StepsCard(
                        stepCount: $alarmStore.alarm.stepCount,
                        presets: stepPresets
                    )

                    // ── Repeat card ──────────────────────────────────────────────
                    RepeatCard(
                        repeatDays: $alarmStore.alarm.repeatDays,
                        weekdayLabels: alarmStore.weekdayLabels
                    )

                    // ── Bottom action bar (in-flow, not floating) ──────────────
                    HStack(spacing: Spacing.m) {
                        EnablePill(enabled: $alarmStore.alarm.enabled, enabledSubtitle: nextFireSubtitle)
                        Spacer(minLength: Spacing.s)
                        TestAlarmButton(action: onRingingStarted)
                    }

                    // Bottom safe-area so the floating tab pill (~64pt) doesn't clip content. 140pt covers BottomPill height + spacing.
                    Color.clear.frame(height: 140)
                }
                .padding(.horizontal, Spacing.l)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Dynamic strings

    /// "Wake at 6:30 AM · In 8h 23m" — dynamic, not a static label.
    private var wakeSubtitle: String {
        guard let fireDate = alarmStore.alarm.nextFireDate() else {
            return alarmStore.alarm.enabled ? "Tap to schedule" : "Disabled"
        }
        let fireFmt = DateFormatter()
        fireFmt.dateFormat = "h:mm a"
        let wakeAt = fireFmt.string(from: fireDate)

        let interval = fireDate.timeIntervalSince(Date())
        let inText = TimeFormatting.relativeUntil(interval)

        return "Wake at \(wakeAt) · \(inText)"
    }

    /// Subtitle for the Enable pill — "Tomorrow at 6:30 AM" etc.
    private var nextFireSubtitle: String {
        guard let fireDate = alarmStore.alarm.nextFireDate() else {
            return "Off"
        }
        let f = DateFormatter()
        f.dateFormat = "EEE h:mm a"
        return f.string(from: fireDate)
    }
}

// MARK: - Steps card

private struct StepsCard: View {
    @Binding var stepCount: Int
    let presets: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                Text("STEPS TO DISMISS")
                    .eyebrow()
                Spacer()
                Text("\(stepCount)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.textPrimary)
                    .numericFlip()
            }

            HStack(spacing: Spacing.xs) {
                ForEach(presets, id: \.self) { value in
                    PresetChip(value: value, selected: stepCount == value) {
                        withAnimation(Motion.spring) {
                            stepCount = value
                        }
                    }
                }
                Spacer(minLength: Spacing.s)
                FineAdjustButton(systemName: "minus", enabled: stepCount > Alarm.minSteps) {
                    withAnimation(Motion.spring) {
                        stepCount = max(Alarm.minSteps, stepCount - 5)
                    }
                }
                FineAdjustButton(systemName: "plus", enabled: stepCount < Alarm.maxSteps) {
                    withAnimation(Motion.spring) {
                        stepCount = min(Alarm.maxSteps, stepCount + 5)
                    }
                }
            }

            Text("Each alarm fires with a slightly different goal to keep it honest.")
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

private struct PresetChip: View {
    let value: Int
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("\(value)")
                .font(.system(size: 15, weight: .semibold).monospacedDigit())
                .foregroundStyle(selected ? Color.textPrimary : Color.textSecondary)
                .frame(width: 52, height: 36)
                .background(
                    Capsule().fill(selected ? Color.sunriseEnd.opacity(0.20) : Color.well)
                )
                .overlay(
                    Capsule().stroke(
                        selected ? Color.sunriseEnd.opacity(0.6) : Color.clear,
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Set steps to \(value)")
    }
}

private struct FineAdjustButton: View {
    let systemName: String
    let enabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(enabled ? Color.textSecondary : Color.textTertiary.opacity(0.4))
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.well))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel("Adjust steps")
    }
}

// MARK: - Repeat card

private struct RepeatCard: View {
    @Binding var repeatDays: Set<Int>
    let weekdayLabels: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("REPEAT")
                .eyebrow()

            HStack(spacing: Spacing.xs) {
                ShortcutChip(label: "Weekdays", active: weekdaysActive) {
                    withAnimation(Motion.spring) { setWeekdays() }
                }
                ShortcutChip(label: "Weekends", active: weekendsActive) {
                    withAnimation(Motion.spring) { setWeekends() }
                }
                ShortcutChip(label: "Every day", active: everyDayActive) {
                    withAnimation(Motion.spring) { setEveryDay() }
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: Spacing.xs) {
                ForEach(1...7, id: \.self) { day in
                    DayDot(
                        day: day,
                        label: weekdayLabels[day - 1],
                        selected: repeatDays.contains(day)
                    ) {
                        withAnimation(Motion.quick) {
                            toggle(day)
                        }
                    }
                }
            }
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - Derived state

    private var weekdaysActive: Bool { repeatDays == Set(1...5) }
    private var weekendsActive: Bool { repeatDays == Set([6, 7]) }
    private var everyDayActive: Bool { repeatDays == Set(1...7) }

    // MARK: - Mutators

    private func toggle(_ day: Int) {
        if repeatDays.contains(day) {
            repeatDays.remove(day)
        } else {
            repeatDays.insert(day)
        }
    }

    private func setWeekdays() {
        if weekdaysActive {
            repeatDays.removeAll()
        } else {
            repeatDays = Set(1...5)
        }
    }

    private func setWeekends() {
        if weekendsActive {
            repeatDays.removeAll()
        } else {
            repeatDays = Set([6, 7])
        }
    }

    private func setEveryDay() {
        if everyDayActive {
            repeatDays.removeAll()
        } else {
            repeatDays = Set(1...7)
        }
    }
}

private struct ShortcutChip: View {
    let label: String
    let active: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(active ? Color.textPrimary : Color.textSecondary)
                .padding(.horizontal, Spacing.s)
                .padding(.vertical, Spacing.xs)
                .background(
                    Capsule().fill(active ? Color.sunriseEnd.opacity(0.20) : Color.well)
                )
                .overlay(
                    Capsule().stroke(
                        active ? Color.sunriseEnd.opacity(0.6) : Color.clear,
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct DayDot: View {
    let day: Int
    let label: String
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Circle()
                    .fill(selected ? Color.sunriseEnd : Color.well)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle().stroke(
                            selected ? Color.sunriseEnd.opacity(0.6) : Color.clear,
                            lineWidth: 4
                        )
                        .blur(radius: 4)
                    )
                Text(label.prefix(1))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(selected ? Color.textPrimary : Color.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Toggle \(label) day")
    }
}

// MARK: - Enable pill (custom — replaces default Toggle)

private struct EnablePill: View {
    @Binding var enabled: Bool
    let enabledSubtitle: String

    var body: some View {
        Button {
            withAnimation(Motion.spring) { enabled.toggle() }
        } label: {
            HStack(spacing: Spacing.s) {
                // Custom switch track with sunrise fill when on.
                Capsule()
                    .fill(enabled ? Color.sunriseGradient : LinearGradient(
                        colors: [Color.well, Color.well],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: 44, height: 26)
                    .overlay(
                        Circle()
                            .fill(Color.textPrimary)
                            .frame(width: 22, height: 22)
                            .offset(x: enabled ? 9 : -9)
                            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(enabled ? "Enabled" : "Disabled")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(enabled ? enabledSubtitle : "Tap to arm")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.horizontal, Spacing.s)
            .frame(height: 56)
            .background(Color.surface, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.05), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(enabled ? "Disable alarm" : "Enable alarm")
        .accessibilityValue(enabledSubtitle)
    }
}

private struct TestAlarmButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "figure.walk.fill")
                .font(.system(size: 20, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.sunriseEnd)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.surface))
                .overlay(Circle().stroke(Color.sunriseEnd.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Test alarm now")
    }
}

// MARK: - Helpers

enum TimeFormatting {
    /// "In 8h 23m" / "In 12m" / "Now" — given seconds until fire.
    static func relativeUntil(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        if total <= 0 { return "Now" }
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "In \(hours)h \(minutes)m"
        } else {
            return "In \(minutes)m"
        }
    }
}