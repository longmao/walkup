//
//  AboutView.swift
//  StepUp — brand narrative (DESIGN_SPEC §3 S4).
//
//  No Form / Section / Label. Free composition: hero, four feature cards,
//  legal/credits footer.
//

import SwiftUI

struct AboutView: View {
    var onBack: () -> Void = {}

    var body: some View {
        ZStack {
            Color.sky.ignoresSafeArea()

            // Top-left back button — replaces the removed RootView bottom pill.
            VStack {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Back to alarm")
                    Spacer()
                }
                .padding(.horizontal, Spacing.m)
                .padding(.top, Spacing.xs)
                Spacer()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    Spacer().frame(height: 56)

                    // ── Hero ────────────────────────────────────────────────────
                    heroSection

                    // ── Four promises ───────────────────────────────────────────
                    VStack(spacing: Spacing.m) {
                        FeatureRow(
                            systemImage: "heart.fill",
                            title: "Free forever",
                            detail: "No subscription, no IAP, no tip jar. Brand promise — never paywalls."
                        )
                        FeatureRow(
                            systemImage: "eye.slash.fill",
                            title: "No tracking",
                            detail: "Steps never leave your device. Local-only."
                        )
                        FeatureRow(
                            systemImage: "figure.walk",
                            title: "CoreMotion",
                            detail: "Hardware step counter. Reliable, no flaky camera tricks."
                        )
                        FeatureRow(
                            systemImage: "lock.shield.fill",
                            title: "Open about it",
                            detail: "Source available. Privacy policy on longmao.github.io."
                        )
                    }

                    // ── Footer ──────────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        Text("LEGAL & LINKS")
                            .eyebrow()

                        LinkRow(
                            systemImage: "doc.text",
                            label: "Privacy policy",
                            url: URL(string: "https://longmao.github.io/walkup-privacy/")!
                        )
                        LinkRow(
                            systemImage: "questionmark.circle",
                            label: "Support",
                            url: URL(string: "https://longmao.github.io/walkup-privacy/")!
                        )
                        HStack {
                            Text("Version")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .font(.system(size: 14, weight: .semibold).monospacedDigit())
                                .foregroundStyle(Color.textPrimary)
                        }
                        .padding(.horizontal, Spacing.m)
                        .frame(height: 44)
                        .background(Color.surface, in: RoundedRectangle(cornerRadius: Radius.button))
                    }

                    // Bottom safe area so the floating pill doesn't clip content.
                    Color.clear.frame(height: 96)
                }
                .padding(.horizontal, Spacing.l)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            // App icon — pulls the asset-catalog version so the brand surface
            // matches the home-screen icon pixel-for-pixel.
            Image("AppIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Walk Up")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text("Walk to wake up.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
                Text("An alarm you can't snooze — because to dismiss it you have to walk. Hardware-pedometer reliable, anti-cheat jitter per fire, no subscription, ever.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
                    .padding(.top, Spacing.xs)
            }
        }
    }
}

// MARK: - Feature row

private struct FeatureRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.sunriseEnd)
                .frame(width: 32, height: 32)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - Link row

private struct LinkRow: View {
    let systemImage: String
    let label: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack(spacing: Spacing.s) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.sunriseEnd)
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, Spacing.m)
            .frame(height: 44)
            .background(Color.surface, in: RoundedRectangle(cornerRadius: Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.button)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}