//
//  OnboardingView.swift
//  StepUp — 3-step onboarding (DESIGN_SPEC §3 S4).
//
//  Shown on first launch only. Once dismissed, the flag is persisted via
//  UserDefaults so the user never sees it again.
//

import SwiftUI
import CoreMotion
import UserNotifications

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var page: Int = 0

    var body: some View {
        ZStack {
            Color.sky.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    WelcomeStep(onNext: { advance() })
                        .tag(0)
                    MotionStep(onNext: { advance() })
                        .tag(1)
                    TestStep(onComplete: { complete() })
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                PageDots(count: 3, current: page)
                    .padding(.bottom, Spacing.xxl)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func advance() {
        withAnimation(Motion.spring) {
            page = min(page + 1, 2)
        }
    }

    private func complete() {
        UserDefaults.standard.set(true, forKey: "stepup.onboarded.v1")

        // Safety net: ensure notification permission has been requested at
        // least once before onboarding dismisses. If the user got here
        // without tapping "Enable motion" (e.g. skipped via swipe), we still
        // want one prompt — never on every cold launch. If they've already
        // decided (granted/denied) we leave the choice alone.
        Task { await ensureNotificationPermissionRequestedOnce() }

        withAnimation(Motion.spring) { isPresented = false }
    }

    /// Asks for notification authorization only when the user hasn't yet
    /// been prompted (status == .notDetermined). Idempotent and silent on
    /// returning users.
    private func ensureNotificationPermissionRequestedOnce() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }
}

// MARK: - Page dots

private struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.sunriseEnd : Color.well)
                    .frame(width: i == current ? 24 : 8, height: 8)
                    .animation(Motion.spring, value: current)
            }
        }
    }
}

// MARK: - Step 1 — Welcome

private struct WelcomeStep: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Editorial sunrise hero — concentric circles evoke a rising sun.
            ZStack {
                Circle()
                    .fill(Color.sunriseEnd.opacity(0.15))
                    .frame(width: 220, height: 220)
                Circle()
                    .fill(Color.sunriseMid.opacity(0.30))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(Color.sunriseEnd)
                    .frame(width: 60, height: 60)
                    .blur(radius: 6)
            }

            VStack(spacing: Spacing.s) {
                Text("Wake up by walking.")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.textPrimary)
                Text("Free forever. No ads. No tracking. The only data we touch is your step count, and only while the alarm is ringing.")
                    .font(.system(size: 15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, Spacing.l)
            }

            Spacer()

            PillButton(title: "Get started", action: onNext)
                .padding(.horizontal, Spacing.l)
                .padding(.bottom, Spacing.xxl)
        }
    }
}

// MARK: - Step 2 — Motion permission

private struct MotionStep: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "figure.walk.motion")
                .font(.system(size: 88, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.sunriseEnd)

            VStack(spacing: Spacing.s) {
                Text("We need motion access.")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.textPrimary)
                Text("Walk Up uses your iPhone's motion sensor to count steps only while the alarm is ringing. We never see or store the data — it stays on your device.")
                    .font(.system(size: 15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, Spacing.l)
            }

            Spacer()

            PillButton(title: "Enable motion", systemImage: "checkmark.circle.fill", action: {
                // Trigger the system prompt, then advance regardless of outcome
                // (the user can still long-press 3s to dismiss if they decline).
                _ = CMPedometer.authorizationStatus()
                let trigger = CMPedometer()
                trigger.startUpdates(from: Date()) { _, _ in }
                trigger.stopUpdates()

                // Bundle the notification permission into this same tap so the
                // user is never ambushed by a separate prompt on a later cold
                // start. iOS coalesces both system prompts naturally; the user
                // sees them back-to-back in the same gesture.
                Task {
                    let center = UNUserNotificationCenter.current()
                    let settings = await center.notificationSettings()
                    if settings.authorizationStatus == .notDetermined {
                        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
                    }
                }

                onNext()
            })
            .padding(.horizontal, Spacing.l)
            .padding(.bottom, Spacing.xxl)
        }
    }
}

// MARK: - Step 3 — Test the alarm

private struct TestStep: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "alarm.waves.left.and.right.fill")
                .font(.system(size: 88, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.sunriseEnd)

            VStack(spacing: Spacing.s) {
                Text("Try it now.")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.textPrimary)
                Text("The alarm fires — you walk to dismiss. 10 to 100 steps, randomized per fire so you can't game it. If you can't walk, hold 3 seconds.")
                    .font(.system(size: 15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, Spacing.l)
            }

            Spacer()

            PillButton(title: "You're all set ✓", systemImage: "checkmark.circle.fill", action: onComplete)
                .padding(.horizontal, Spacing.l)
                .padding(.bottom, Spacing.xxl)
        }
    }
}

// MARK: - Reusable pill button

private struct PillButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.sunriseGradient, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}