//
//  AlarmRingingView.swift
//  StepUp — full-screen alarm ringing UI (DESIGN_SPEC §3 S2 — "Sunrise ring").
//
//  Hero is a custom Path ring that crossfades through the sunrise palette as
//  steps accumulate, with a 96pt monospaced-digit step counter at center and
//  progressive haptics as the user walks toward the goal.
//

import SwiftUI
import UIKit

struct AlarmRingingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject var stepCounter: StepCounter
    let requiredSteps: Int
    let currentSteps: Int
    let onEmergencyDismiss: () -> Void

    @State private var breathScale: CGFloat = 1.0
    @State private var goalBurst: Bool = false
    @State private var lastHapticBucket: Int = -1

    private var progress: Double {
        guard requiredSteps > 0 else { return 0 }
        return min(1.0, Double(currentSteps) / Double(requiredSteps))
    }

    private var goalReached: Bool {
        currentSteps >= requiredSteps
    }

    /// Bucket for progressive haptics. 0 = 0-50% (every 5 steps), 1 = 50-80%
    /// (every 3 steps), 2 = 80-99% (every 1 step), 3 = goal reached.
    private var hapticBucket: Int {
        if goalReached { return 3 }
        if progress >= 0.8 { return 2 }
        if progress >= 0.5 { return 1 }
        return 0
    }

    var body: some View {
        ZStack {
            // Sunrise gradient background — linear, since meshGradient needs iOS 18+.
            Color.ringingBackground
                .ignoresSafeArea()

            // Subtle radial glow behind the ring — anchors the eye.
            RadialGradient(
                colors: [Color.sunriseMid.opacity(0.30), Color.clear],
                center: .center,
                startRadius: 40,
                endRadius: 280
            )
            .ignoresSafeArea()
            .scaleEffect(breathScale)
            .opacity(reduceMotion ? 1.0 : 1.0)

            // Goal burst — golden radial overlay when the user hits the goal.
            if goalBurst {
                RadialGradient(
                    colors: [Color.sunriseEnd.opacity(0.65), Color.sunriseMid.opacity(0.25), Color.clear],
                    center: .center,
                    startRadius: 10,
                    endRadius: 420
                )
                .ignoresSafeArea()
                .transition(.opacity)
            }

            VStack(spacing: Spacing.l) {
                Spacer()

                // ── Header ────────────────────────────────────────────────────
                VStack(spacing: Spacing.xs) {
                    Text("WAKE UP")
                        .eyebrow()
                        .foregroundStyle(Color.textSecondary)
                    Text(goalReached ? "Sun's up ✓" : "Walk to dismiss")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                }

                // ── Hero ring + counter ───────────────────────────────────────
                ZStack {
                    SunriseRing(
                        progress: progress,
                        lineWidth: 18,
                        reduceMotion: reduceMotion
                    )
                    .frame(width: 260, height: 260)

                    VStack(spacing: Spacing.xxs) {
                        Text("\(currentSteps)")
                            .font(.system(size: 96, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Color.textPrimary)
                            .numericFlip()
                        Text(subtitleText)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                            .tracking(0.05)
                            .textCase(.uppercase)
                    }
                }
                .scaleEffect(breathScale)

                Spacer()

                // ── Action ────────────────────────────────────────────────────
                if goalReached {
                    StopAlarmButton(action: onEmergencyDismiss)
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                } else {
                    EmergencyHoldButton(onDismiss: onEmergencyDismiss)
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.bottom, Spacing.xxl)
        }
        .onAppear {
            startBreath()
            triggerHaptic(forBucket: hapticBucket)
        }
        .onChange(of: currentSteps) { _, _ in
            // Cross-bucket haptic escalation as the user walks.
            let bucket = hapticBucket
            if bucket != lastHapticBucket {
                triggerHaptic(forBucket: bucket)
                lastHapticBucket = bucket
            }
        }
        .onChange(of: goalReached) { _, reached in
            withAnimation(Motion.spring) {
                goalBurst = reached
            }
            if reached {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private var subtitleText: String {
        if goalReached { return "Goal reached" }
        let remaining = max(0, requiredSteps - currentSteps)
        return "\(remaining) steps to sunrise"
    }

    // MARK: - Breath loop

    private func startBreath() {
        guard !reduceMotion else { return }
        withAnimation(Motion.breath.repeatForever(autoreverses: true)) {
            breathScale = 1.04
        }
    }

    // MARK: - Haptics

    private func triggerHaptic(forBucket bucket: Int) {
        let generator = UIImpactFeedbackGenerator(style: bucket >= 2 ? .heavy : (bucket == 1 ? .medium : .light))
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Sunrise ring

/// Custom Path ring that draws the progress arc and crossfades through the
/// sunrise palette (purple → coral → gold) as progress climbs.
private struct SunriseRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            // Outer track — dim sunrise start, anchors the eye.
            Circle()
                .stroke(Color.sunriseStart.opacity(0.30), lineWidth: lineWidth)

            // Progress arc — color shifts along the sunrise gradient.
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(
                    Color.sunriseGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : Motion.spring, value: progress)

            // Inner soft halo on the leading edge — gives the arc dimension.
            Circle()
                .trim(from: max(0, progress - 0.02), to: progress)
                .stroke(Color.sunriseEnd.opacity(0.7), lineWidth: lineWidth * 0.55)
                .rotationEffect(.degrees(-90))
                .blur(radius: 8)
                .animation(reduceMotion ? nil : Motion.spring, value: progress)
        }
    }
}

// MARK: - Stop alarm button

private struct StopAlarmButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                Text("Stop alarm")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.sunriseGradient, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stop the alarm")
    }
}

// MARK: - Emergency hold (3s long-press)

private struct EmergencyHoldButton: View {
    let onDismiss: () -> Void

    @State private var holdProgress: CGFloat = 0
    @State private var didFire: Bool = false

    var body: some View {
        VStack(spacing: Spacing.s) {
            Text("Can't walk?")
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)

            // Custom button: thin capsule with stroke-fill that tracks the long-press.
            ZStack {
                Capsule()
                    .fill(Color.well.opacity(0.45))
                Capsule()
                    .trim(from: 0, to: holdProgress)
                    .fill(Color.emergency.opacity(0.85))
                    .animation(.linear(duration: 0.05), value: holdProgress)
                HStack(spacing: Spacing.s) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                    Text("Hold 3s to dismiss")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.textPrimary)
            }
            .frame(height: 56)
            .overlay(Capsule().stroke(Color.white.opacity(0.06), lineWidth: 1))
            .contentShape(Capsule())
            .gesture(
                LongPressGesture(minimumDuration: 3.0)
                    .onChanged { _ in
                        guard !didFire else { return }
                        // Drive a manual progress sweep — gives visual feedback during the press.
                        withAnimation(.linear(duration: 3.0)) {
                            holdProgress = 1
                        }
                    }
                    .onEnded { _ in
                        guard !didFire else { return }
                        didFire = true
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        onDismiss()
                    }
            )
            .accessibilityLabel("Hold 3 seconds to dismiss")
        }
        .onAppear { holdProgress = 0 }
    }
}