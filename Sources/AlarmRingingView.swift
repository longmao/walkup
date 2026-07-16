//
//  AlarmRingingView.swift
//  StepUp — full-screen alarm ringing UI with step progress + emergency fallback.
//

import SwiftUI

struct AlarmRingingView: View {
    let requiredSteps: Int
    let currentSteps: Int
    @Binding var emergencyHold: Double
    let onEmergencyDismiss: () -> Void

    private var progress: Double {
        guard requiredSteps > 0 else { return 0 }
        return min(1.0, Double(currentSteps) / Double(requiredSteps))
    }

    private var goalReached: Bool {
        currentSteps >= requiredSteps
    }

    var body: some View {
        ZStack {
            (goalReached ? Color.green : Color.accentColor)
                .ignoresSafeArea()
                .opacity(0.85)

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Wake up!")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                    Text(goalReached ? "Goal reached — tap to stop" : "Walk to dismiss")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))
                }

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.3), value: progress)
                    VStack {
                        Text("\(currentSteps)")
                            .font(.system(size: 72, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                        Text("of \(requiredSteps) steps")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .frame(width: 240, height: 240)

                if goalReached {
                    Button(action: onEmergencyDismiss) {
                        Text("Stop alarm")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .foregroundStyle(.green)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                } else {
                    // Emergency fallback: long-press 3 seconds to dismiss (compliance 5.1.1(iv)).
                    VStack(spacing: 8) {
                        Text("Can't walk?")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.85))
                        Button(action: {}) {
                            Text("Hold 3s to dismiss")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.2))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 3.0)
                                .onChanged { _ in
                                    emergencyHold = 1
                                    onEmergencyDismiss()
                                }
                                .onEnded { _ in emergencyHold = 0 }
                        )
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
        }
    }
}