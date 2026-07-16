//
//  AlarmSound.swift
//  StepUp — looping alarm tone + haptic feedback
//

import Foundation
import AVFoundation
import AudioToolbox
import UIKit

/// Plays a looping alarm tone and runs haptic vibration. Auto-stops on `stop()`.
@MainActor
final class AlarmSound {
    static let shared = AlarmSound()

    private var player: AVAudioPlayer?

    func start() {
        configureSession()
        playSystemAlarm()
        startHapticLoop()
    }

    func stop() {
        player?.stop()
        player = nil
        // Note: AudioServicesStopSystemSoundID was removed in iOS 27 SDK.
        // It was a no-op for short system sounds anyway — AVAudioPlayer.stop() is sufficient.
        // No clean cancellation for haptic loop — fires for a few more seconds, harmless.
    }

    // MARK: - Private

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Non-fatal: system default alarm will still play.
        }
    }

    private func playSystemAlarm() {
        // Use the system alarm sound — universal, attention-grabbing, no asset bundling.
        let url = Bundle.main.url(forResource: "alarm", withExtension: "caf")
            ?? URL(fileURLWithPath: "/System/Library/Audio/UISounds/alarm.caf")
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1  // loop forever
            player?.prepareToPlay()
            player?.play()
        } catch {
            // Fallback: system sound
            AudioServicesPlayAlertSound(SystemSoundID(1304))
        }
    }

    private func startHapticLoop() {
        // 注：iOS 26 推荐用 SwiftUI .sensoryFeedback 替代此循环。
        // 因 AlarmSound 是 @MainActor 旧 API 类 · 暂保留。
        // RootView 调用 AlarmRingingView 时可改用 .sensoryFeedback(.warning, trigger: ...)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        Task { @MainActor in
            while player?.isPlaying == true {
                generator.notificationOccurred(.warning)
                try? await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5s
            }
        }
    }
}