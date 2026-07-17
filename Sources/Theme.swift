//
//  Theme.swift
//  StepUp — Design system tokens (DESIGN_SPEC v0.2 §2).
//
//  Dark-by-default. Sunrise gradient is the hero accent.
//  No third-party fonts/icons/animations. iOS 17+ only.
//

import SwiftUI

// MARK: - Color tokens

extension Color {
    /// Background layers (dark by default — 5am wake-up should not blast light).
    static let sky = Color(red: 0.055, green: 0.075, blue: 0.125)        // #0E1320
    static let surface = Color(red: 0.102, green: 0.133, blue: 0.220)    // #1A2238
    static let well = Color(red: 0.145, green: 0.176, blue: 0.267)       // #252D44

    /// Sunrise gradient — purple → coral → gold (rings the wake-up beat).
    static let sunriseStart = Color(red: 0.239, green: 0.165, blue: 0.431)  // #3D2A6E
    static let sunriseMid   = Color(red: 0.886, green: 0.416, blue: 0.302)  // #E26A4D
    static let sunriseEnd   = Color(red: 0.965, green: 0.753, blue: 0.396)  // #F6C065

    /// Semantic accents.
    static let steady     = Color(red: 0.482, green: 0.537, blue: 0.957)  // #7B89F4 — step count ring
    static let goal       = Color(red: 0.431, green: 0.906, blue: 0.718)  // #6EE7B7 — reached
    static let emergency  = Color(red: 0.973, green: 0.443, blue: 0.443)  // #F87171 — fallback

    /// Text — warm off-white primary so it pairs with sunrise, not the dead white of stock UI.
    static let textPrimary   = Color(red: 0.961, green: 0.945, blue: 0.910)  // #F5F1E8
    static let textSecondary = Color(red: 0.627, green: 0.659, blue: 0.737)  // #A0A8BC
    static let textTertiary  = Color(red: 0.353, green: 0.380, blue: 0.471)  // #5A6178

    /// Hero sunrise gradient (linear — mesh is iOS 18+, we target 17).
    static let sunriseGradient = LinearGradient(
        colors: [sunriseStart, sunriseMid, sunriseEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Ringing background — deep sky, slight tilt for depth (no flat fill).
    static let ringingBackground = LinearGradient(
        colors: [sky, Color(red: 0.06, green: 0.05, blue: 0.15)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Spacing (8pt grid, 4pt micro-adjust)

enum Spacing {
    static let xxs: CGFloat = 4
    static let xs:  CGFloat = 8
    static let s:   CGFloat = 12
    static let m:   CGFloat = 16
    static let l:   CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Shape

enum Radius {
    static let card:   CGFloat = 20
    static let hero:   CGFloat = 28
    static let button: CGFloat = 14
    static let pill:   CGFloat = 9999
}

// MARK: - Motion DNA

enum Motion {
    /// Slow, weighted spring — gives motion a breath instead of a click.
    static let spring = SwiftUI.Animation.spring(response: 0.55, dampingFraction: 0.78)
    /// Quicker spring for tight feedback (chip toggle, step bump).
    static let quick  = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)
    /// Long breath — the 1.5s pulse behind the sunrise ring.
    static let breath = SwiftUI.Animation.easeInOut(duration: 1.5)
}

// MARK: - Typography modifiers

extension View {
    /// Time hero — 96pt heavy rounded, used for Setup time + ringing numerals.
    func timeHero() -> some View {
        self
            .font(.system(size: 96, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Color.textPrimary)
    }

    /// Hero subtitle — 17pt regular warm off-white.
    func heroSubtitle() -> some View {
        self
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(Color.textPrimary.opacity(0.85))
    }

    /// Section eyebrow — uppercase tracked label.
    func eyebrow() -> some View {
        self
            .font(.system(size: 11, weight: .semibold))
            .textCase(.uppercase)
            .tracking(0.08)
            .foregroundStyle(Color.textSecondary)
    }

    /// Numeric flip on value change — used for the steps counter, time hero.
    func numericFlip() -> some View {
        self.contentTransition(.numericText())
    }
}