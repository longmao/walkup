//
//  StepCounter.swift
//  StepUp — CMPedometer wrapper for step counting during alarm
//

import Foundation
import CoreMotion
import Combine

/// Streams live step counts from CoreMotion while the alarm is ringing.
/// - Starts from a fresh baseline when `begin()` is called.
/// - Authorizes Motion access on first use.
@MainActor
final class StepCounter: ObservableObject {
    @Published private(set) var currentSteps: Int = 0
    @Published private(set) var isCounting: Bool = false
    @Published private(set) var authorizationStatus: CMAuthorizationStatus = .notDetermined

    private let pedometer = CMPedometer()
    private var startDate: Date?

    init() {
        authorizationStatus = CMPedometer.authorizationStatus()
    }

    /// Request permission and start counting from now.
    func begin() {
        CMPedometer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                if status == .authorized {
                    self?.startCounting()
                }
            }
        }
    }

    private func startCounting() {
        guard CMPedometer.isStepCountingAvailable() else {
            // Hardware unavailable — caller should show fallback.
            return
        }
        currentSteps = 0
        startDate = Date()
        isCounting = true
        pedometer.startUpdates(from: startDate!) { [weak self] data, _ in
            guard let self, let data else { return }
            DispatchQueue.main.async {
                self.currentSteps = data.numberOfSteps.intValue
            }
        }
    }

    func stop() {
        pedometer.stopUpdates()
        isCounting = false
    }

    /// Resets the counter and starts fresh from now. Used if user re-arms the alarm.
    func reset() {
        stop()
        begin()
    }

    deinit {
        pedometer.stopUpdates()
    }
}