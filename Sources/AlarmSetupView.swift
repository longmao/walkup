//
//  AlarmSetupView.swift
//  StepUp — main screen: pick a time, set steps, choose repeat days.
//

import SwiftUI

struct AlarmSetupView: View {
    @EnvironmentObject var alarmStore: AlarmStore

    /// Optional manual fire (for testing without waiting).
    var onRingingStarted: () -> Void

    private var timeBinding: Binding<Date> {
        Binding(
            get: { alarmStore.alarm.time },
            set: { alarmStore.alarm.time = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Time") {
                    DatePicker("Wake up at", selection: timeBinding, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .accessibilityLabel("Set wake up time")
                }

                Section {
                    HStack {
                        Text("Steps to dismiss")
                        Spacer()
                        Text("\(alarmStore.alarm.stepCount)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Stepper(
                        "Adjust",
                        value: Binding(
                            get: { alarmStore.alarm.stepCount },
                            set: { alarmStore.alarm.stepCount = max(Alarm.minSteps, min(Alarm.maxSteps, $0)) }
                        ),
                        in: Alarm.minSteps...Alarm.maxSteps,
                        step: 5
                    )
                    .labelsHidden()
                    .accessibilityLabel("Adjust steps to dismiss")
                } header: {
                    Text("Walk to dismiss")
                } footer: {
                    Text("Each alarm fires with a slightly different goal to keep it honest.")
                }

                Section("Repeat") {
                    HStack(spacing: 6) {
                        ForEach(1...7, id: \.self) { day in
                            DayChip(
                                day: day,
                                label: alarmStore.weekdayLabels[day - 1],
                                selected: alarmStore.alarm.repeatDays.contains(day),
                                onTap: { toggleDay(day) }
                            )
                        }
                    }
                }

                Section {
                    Toggle("Enabled", isOn: Binding(
                        get: { alarmStore.alarm.enabled },
                        set: { alarmStore.alarm.enabled = $0 }
                    ))
                    .accessibilityLabel("Enable alarm")
                }

                Section {
                    Button {
                        onRingingStarted()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Test alarm now")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Test the alarm now")
                } footer: {
                    Text("Test fires the alarm immediately so you can try the walk-to-dismiss flow without waiting for the scheduled time.")
                }
            }
            .navigationTitle("Walk Up")
        }
    }

    private func toggleDay(_ day: Int) {
        if alarmStore.alarm.repeatDays.contains(day) {
            alarmStore.alarm.repeatDays.remove(day)
        } else {
            alarmStore.alarm.repeatDays.insert(day)
        }
        // AlarmStore.alarm.didSet reschedules when hasLoaded is true.
    }
}

private struct DayChip: View {
    let day: Int
    let label: String
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label.prefix(1))
                .font(.subheadline.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(selected ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Toggle \(label) day")
    }
}