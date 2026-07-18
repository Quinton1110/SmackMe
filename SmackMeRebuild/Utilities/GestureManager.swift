//
//  GestureManager.swift
//  SmackMe
//
//  Handles gesture and motion detection
//

import UIKit
import CoreMotion

protocol GestureManagerDelegate: AnyObject {
    func gestureDetected(_ action: GameAction)
}

class GestureManager: NSObject {
    weak var delegate: GestureManagerDelegate?

    private let motionManager = CMMotionManager()
    private var lastAcceleration: CMAcceleration?
    private var freezeTimer: Timer?
    private var isFrozen = false

    /// How long the player must hold still for freeze. Scales with BPM:
    /// 1.0s at low BPMs, shorter at high BPMs so freeze remains possible.
    var freezeDuration: TimeInterval = 1.0

    private var tapRecognizer: UITapGestureRecognizer!
    private var pinchRecognizer: UIPinchGestureRecognizer!

    // Motion cooldown: after ANY gesture fires, block motion gestures for this
    // duration. Prevents cross-type interference (e.g. tap jolt triggering shake).
    // Touch gestures (tap/pinch) are deliberate and always allowed - they must
    // cause game over if the player touches during freeze.
    private var lastGestureTime: Date?
    private let motionCooldown: TimeInterval = 0.6

    /// Record that a gesture just fired. Called by all gesture types.
    private func markGestureFired() {
        lastGestureTime = Date()
    }

    /// Returns true if motion gestures should be allowed (cooldown expired).
    private func shouldAllowMotionGesture() -> Bool {
        if let lastTime = lastGestureTime, Date().timeIntervalSince(lastTime) < motionCooldown {
            return false
        }
        return true
    }

    func setup(on view: UIView) {
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapRecognizer)

        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        view.addGestureRecognizer(pinchRecognizer)

        startMotionDetection()
    }

    func cleanup() {
        stopMotionDetection()
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            // Always fire - touching during freeze must cause game over
            cancelFreezeDetection()
            markGestureFired()
            delegate?.gestureDetected(.smack)
        }
    }

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        if recognizer.state == .ended {
            cancelFreezeDetection()
            markGestureFired()
            delegate?.gestureDetected(.pinch)
        }
    }

    private func startMotionDetection() {
        guard motionManager.isAccelerometerAvailable else { return }

        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let acceleration = data?.acceleration else { return }

            self.detectShake(acceleration: acceleration)
            self.detectLift(acceleration: acceleration)
            self.detectFreeze(acceleration: acceleration)

            self.lastAcceleration = acceleration
        }
    }

    private func stopMotionDetection() {
        motionManager.stopAccelerometerUpdates()
        freezeTimer?.invalidate()
    }

    private func detectShake(acceleration: CMAcceleration) {
        guard let last = lastAcceleration else { return }

        let deltaX = abs(acceleration.x - last.x)
        let deltaY = abs(acceleration.y - last.y)
        let deltaZ = abs(acceleration.z - last.z)

        // Lower threshold for a lighter, quicker shake
        let shakeThreshold: Double = 1.5

        if deltaX > shakeThreshold || deltaY > shakeThreshold || deltaZ > shakeThreshold {
            if shouldAllowMotionGesture() {
                markGestureFired()
                delegate?.gestureDetected(.shake)
            }
        }
    }

    private func detectLift(acceleration: CMAcceleration) {
        // Orientation-independent lift detection using total acceleration magnitude.
        // At rest (any orientation), total accel ≈ 1.0g (just gravity).
        // Lifting the phone adds upward force, briefly pushing total accel > 1.0g.
        // Threshold of 1.3g detects a moderate upward lift regardless of phone angle.
        // No global cooldown - the VC filters by expected action.
        let totalAccel = sqrt(acceleration.x * acceleration.x +
                              acceleration.y * acceleration.y +
                              acceleration.z * acceleration.z)
        let liftThreshold: Double = 1.3

        if totalAccel > liftThreshold {
            delegate?.gestureDetected(.lift)
        }
    }

    private func detectFreeze(acceleration: CMAcceleration) {
        guard let last = lastAcceleration else { return }

        let deltaX = abs(acceleration.x - last.x)
        let deltaY = abs(acceleration.y - last.y)
        let deltaZ = abs(acceleration.z - last.z)

        // Forgiving threshold - normal hand tremor can exceed 0.05 easily
        let movementThreshold: Double = 0.15

        if deltaX < movementThreshold && deltaY < movementThreshold && deltaZ < movementThreshold {
            // Only start if not already frozen AND no timer is already running.
            // Without the freezeTimer check, this fires every 0.1s and keeps
            // restarting the timer so it never reaches 1 second.
            if !isFrozen && freezeTimer == nil {
                startFreezeDetection()
            }
        } else {
            cancelFreezeDetection()
        }
    }

    /// Reset freeze state so detection starts fresh (called when a new action appears).
    func resetFreezeState() {
        isFrozen = false
        freezeTimer?.invalidate()
        freezeTimer = nil
    }

    private func startFreezeDetection() {
        freezeTimer?.invalidate()
        // Require freezeDuration seconds of stillness to trigger freeze.
        // Scales with BPM so freeze remains achievable at high tempos.
        freezeTimer = Timer.scheduledTimer(withTimeInterval: freezeDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.isFrozen = true
            self.delegate?.gestureDetected(.freeze)
        }
    }

    private func cancelFreezeDetection() {
        isFrozen = false
        freezeTimer?.invalidate()
        freezeTimer = nil
    }
}
