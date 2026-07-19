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

    /// Timestamp of the most recent movement beyond the stillness threshold.
    /// Freeze is now resolved by the game engine, which asks hasBeenStill(since:)
    /// at a beat aligned boundary. Tracking movement continuously (instead of a
    /// self restarting timer) is what keeps consecutive freezes locked to the
    /// beat and never requires the player to move between them.
    private var lastMovementTime: Date?

    private var pinchRecognizer: UIPinchGestureRecognizer!

    // Motion cooldown: after ANY gesture fires, block motion gestures for this
    // duration. Prevents cross type interference (a shake also tripping the lift
    // detector, or a tap jolt registering as a shake).
    private var lastGestureTime: Date?
    // Short: long enough to stop one physical gesture from double firing, short
    // enough that it never swallows the next slot's shake. Also reset at the
    // start of every cue so each slot begins clean.
    private let motionCooldown: TimeInterval = 0.3

    // Lift edge detection: only fire on the rising edge (below then above the
    // threshold) so one physical lift registers once, not on every tick.
    private var liftIsActive = false

    // True if the current accelerometer sample looked like a shake. Used to keep
    // that same jerk from also being counted as a lift.
    private var shakeMotionThisTick = false

    /// Record that a gesture just fired. Called by all gesture types.
    private func markGestureFired() {
        lastGestureTime = Date()
    }

    /// Clear the motion cooldown so each new cue's slot starts fresh. Without
    /// this, continuous shaking keeps the cooldown perpetually armed and the one
    /// shake the slot needs gets swallowed, which reads as a miss and a loss.
    func resetMotionCooldown() {
        lastGestureTime = nil
    }

    /// Returns true if motion gestures should be allowed (cooldown expired).
    private func shouldAllowMotionGesture() -> Bool {
        if let lastTime = lastGestureTime, Date().timeIntervalSince(lastTime) < motionCooldown {
            return false
        }
        return true
    }

    func setup(on view: UIView) {
        // Smack is handled by the view controller's touchesBegan (fires on touch
        // down), so no tap recognizer: a tap recognizer also fired on finger-lift,
        // producing a second smack that landed on the next cue and lost the game.
        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        view.addGestureRecognizer(pinchRecognizer)

        startMotionDetection()
    }

    func cleanup() {
        stopMotionDetection()
    }

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        // Fire the moment the pinch is recognized, not on release. Waiting for
        // .ended meant a natural or slightly slow pinch often didn't complete
        // before the slot ended, reading as a miss even though the player pinched.
        if recognizer.state == .began {
            markGestureFired()
            delegate?.gestureDetected(.pinch)
        }
    }

    private func startMotionDetection() {
        guard motionManager.isAccelerometerAvailable else { return }

        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let acceleration = data?.acceleration else { return }

            self.shakeMotionThisTick = false
            self.detectShake(acceleration: acceleration)
            self.detectLift(acceleration: acceleration)
            self.trackStillness(acceleration: acceleration)

            self.lastAcceleration = acceleration
        }
    }

    private func stopMotionDetection() {
        motionManager.stopAccelerometerUpdates()
    }

    private func detectShake(acceleration: CMAcceleration) {
        guard let last = lastAcceleration else { return }

        let deltaX = abs(acceleration.x - last.x)
        let deltaY = abs(acceleration.y - last.y)
        let deltaZ = abs(acceleration.z - last.z)

        // Threshold for a shake. Low enough that a normal, unforceful shake
        // registers reliably (a missed shake is an instant loss on the grid),
        // but still well above a smooth lift's frame to frame delta so a lift
        // never reads as a shake.
        let shakeThreshold: Double = 1.1

        if deltaX > shakeThreshold || deltaY > shakeThreshold || deltaZ > shakeThreshold {
            // Mark the sample as shake-like even when the cooldown blocks the
            // fire, so this same jerk can't also register as a lift.
            shakeMotionThisTick = true
            if shouldAllowMotionGesture() {
                markGestureFired()
                delegate?.gestureDetected(.shake)
            }
        }
    }

    private func detectLift(acceleration: CMAcceleration) {
        // Orientation independent lift detection using total acceleration magnitude.
        // At rest (any orientation), total accel is about 1.0g (just gravity).
        // Lifting the phone adds upward force, briefly pushing total accel above 1.0g.
        // Threshold of 1.3g detects a moderate upward lift regardless of phone angle.
        let totalAccel = sqrt(acceleration.x * acceleration.x +
                              acceleration.y * acceleration.y +
                              acceleration.z * acceleration.z)
        // Lower threshold so a gentle, natural lift crosses it. At rest total
        // accel is about 1.0g; a soft lift only reaches about 1.1 to 1.2g.
        let liftThreshold: Double = 1.15

        if totalAccel > liftThreshold {
            // Rising edge only: fire once when crossing the threshold, then wait
            // for the signal to drop back below it before it can fire again.
            if !liftIsActive {
                liftIsActive = true
                delegate?.gestureDetected(.lift)
            }
        } else {
            liftIsActive = false
        }
    }

    /// Continuously track movement so the engine can ask whether the player has
    /// held still. Freeze completion is owned by the engine and beat aligned.
    private func trackStillness(acceleration: CMAcceleration) {
        guard let last = lastAcceleration else { return }

        let deltaX = abs(acceleration.x - last.x)
        let deltaY = abs(acceleration.y - last.y)
        let deltaZ = abs(acceleration.z - last.z)

        // Forgiving threshold. Normal hand tremor can exceed 0.05 easily.
        let movementThreshold: Double = 0.15

        if deltaX >= movementThreshold || deltaY >= movementThreshold || deltaZ >= movementThreshold {
            lastMovementTime = Date()
        }
    }

    /// True if the player has not moved beyond the stillness threshold since the
    /// given time. Used by the engine to resolve a freeze at a beat boundary.
    func hasBeenStill(since date: Date) -> Bool {
        guard let moved = lastMovementTime else { return true }
        return moved <= date
    }
}
