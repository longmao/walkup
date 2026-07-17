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

    /// Start counting from now. Permission is requested implicitly by `startUpdates`
    /// (system presents the prompt the first time the user takes steps under the alarm).
    func begin() {
        authorizationStatus = CMPedometer.authorizationStatus()
        startCounting()
    }

    private func startCounting() {
        // Headless-test escape hatch: when AUTOTEST_NO_MOTION is set, mark counting
        // so the UI shows the in-progress ring but skip the hardware call (which
        // implicitly triggers the NSMotionUsageDescription prompt on first use).
        if ProcessInfo.processInfo.environment["AUTOTEST_NO_MOTION"] != nil {
            currentSteps = 0
            startDate = Date()
            isCounting = true
            NSLog("[StepCounter] AUTOTEST_NO_MOTION — skipped CMPedometer call")
            return
        }

        guard CMPedometer.isStepCountingAvailable() else {
            NSLog("[StepCounter] isStepCountingAvailable()=false — hardware unavailable")
            return
        }

        currentSteps = 0
        startDate = Date()
        isCounting = true
        authorizationStatus = CMPedometer.authorizationStatus()
        NSLog("[StepCounter] begin — authStatus=\(authorizationStatus.rawValue) (0=notDetermined 1=restricted 2=denied 3=authorized) — starting updates...")

        let didStart = pedometer.startUpdates(from: startDate!) { [weak self] data, error in
            guard let self else { return }
            if let error {
                NSLog("[StepCounter] startUpdates error: \(error.localizedDescription)")
                return
            }
            guard let data else {
                NSLog("[StepCounter] startUpdates callback fired with nil data")
                return
            }
            let count = data.numberOfSteps.intValue
            DispatchQueue.main.async {
                NSLog("[StepCounter] update — steps=\(count)")
                self.currentSteps = count
            }
        }
        NSLog("[StepCounter] startUpdates returned \(didStart)")
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