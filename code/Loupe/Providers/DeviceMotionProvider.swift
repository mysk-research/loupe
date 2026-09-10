//
//  DeviceMotionProvider.swift
//  Loupe
//
//  Everything CMMotionManager exposes — the raw inertial samples
//  (accelerometer, gyroscope, uncalibrated magnetometer) and the fused
//  CMDeviceMotion frame (attitude, gravity, user acceleration, calibrated
//  magnetic field, compass heading) — is available without the iOS Motion
//  prompt, making this a fully passive surface.
//

import Foundation

#if os(iOS)
@preconcurrency import CoreMotion
#endif

#if os(iOS)
final class DeviceMotionProvider: SignalProvider, LiveSignalProvider {
    let category: SignalCategory = .deviceMotion
    let updateInterval: TimeInterval = 0.2

    private static let accelerometerRationale =
        String(localized: "3-axis acceleration in g.", comment: "Signal card rationale beneath the Accelerometer value in the Device Motion category.")
    private static let gyroRationale =
        String(localized: "3-axis rotation rate in rad/s (uncalibrated).", comment: "Signal card rationale beneath the Gyroscope (raw) value in the Device Motion category.")
    private static let magnetometerRationale =
        String(localized: "3-axis magnetic field in µT (uncalibrated).", comment: "Signal card rationale beneath the Magnetometer (raw) value in the Device Motion category.")
    private static let attitudeRationale =
        String(localized: "Fused orientation as roll, pitch, and yaw in degrees.", comment: "Signal card rationale beneath the Attitude value in the Device Motion category.")
    private static let gravityRationale =
        String(localized: "Gravity vector in g, separated from user-induced acceleration by the system.", comment: "Signal card rationale beneath the Gravity value in the Device Motion category.")
    private static let userAccelRationale =
        String(localized: "Acceleration in g with gravity removed.", comment: "Signal card rationale beneath the User acceleration value in the Device Motion category.")
    private static let rotationFusedRationale =
        String(localized: "Bias-corrected rotation rate in rad/s.", comment: "Signal card rationale beneath the Rotation rate (bias-corrected) value in the Device Motion category.")
    private static let calibratedMagRationale =
        String(localized: "Calibrated 3-axis magnetic field in µT with accuracy indicator.", comment: "Signal card rationale beneath the Magnetic field (calibrated) value in the Device Motion category.")
    private static let headingRationale =
        String(localized: "Compass bearing in degrees relative to magnetic north.", comment: "Signal card rationale beneath the Compass heading value in the Device Motion category.")

    func collect() async -> [FingerprintSignal] {
        let motion = CMMotionManager()
        let frame = Self.bestAvailableFrame()
        Self.startUpdates(motion: motion, interval: 0.05, frame: frame)
        try? await Task.sleep(nanoseconds: 250_000_000)
        let signals = Self.signals(category: category, motion: motion, frame: frame)
        Self.stopUpdates(motion: motion)
        return signals
    }

    func stream() -> AsyncStream<[FingerprintSignal]> {
        AsyncStream { continuation in
            let motion = CMMotionManager()
            guard motion.isAccelerometerAvailable
                || motion.isGyroAvailable
                || motion.isMagnetometerAvailable
                || motion.isDeviceMotionAvailable
            else {
                continuation.finish()
                return
            }

            let frame = Self.bestAvailableFrame()
            Self.startUpdates(motion: motion, interval: self.updateInterval, frame: frame)

            let category = self.category
            let timer = DispatchSource.makeTimerSource(queue: .global(qos: .userInitiated))
            timer.schedule(deadline: .now() + self.updateInterval, repeating: self.updateInterval)
            timer.setEventHandler {
                continuation.yield(Self.signals(category: category, motion: motion, frame: frame))
            }
            timer.resume()

            continuation.onTermination = { @Sendable _ in
                timer.cancel()
                Task { @MainActor in
                    Self.stopUpdates(motion: motion)
                }
            }
        }
    }

    // MARK: - Reference Frame

    private static func bestAvailableFrame() -> CMAttitudeReferenceFrame? {
        let available = CMMotionManager.availableAttitudeReferenceFrames()
        if available.contains(.xMagneticNorthZVertical) { return .xMagneticNorthZVertical }
        if available.contains(.xArbitraryCorrectedZVertical) { return .xArbitraryCorrectedZVertical }
        if available.contains(.xArbitraryZVertical) { return .xArbitraryZVertical }
        return nil
    }

    private static func isNorthAligned(_ frame: CMAttitudeReferenceFrame?) -> Bool {
        guard let frame else { return false }
        return frame == .xMagneticNorthZVertical || frame == .xTrueNorthZVertical
    }

    // MARK: - Sensor Lifecycle

    private static func startUpdates(motion: CMMotionManager, interval: TimeInterval, frame: CMAttitudeReferenceFrame?) {
        if motion.isAccelerometerAvailable {
            motion.accelerometerUpdateInterval = interval
            motion.startAccelerometerUpdates()
        }
        if motion.isGyroAvailable {
            motion.gyroUpdateInterval = interval
            motion.startGyroUpdates()
        }
        if motion.isMagnetometerAvailable {
            motion.magnetometerUpdateInterval = interval
            motion.startMagnetometerUpdates()
        }
        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = interval
            if let frame {
                motion.startDeviceMotionUpdates(using: frame)
            } else {
                motion.startDeviceMotionUpdates()
            }
        }
    }

    private static func stopUpdates(motion: CMMotionManager) {
        motion.stopAccelerometerUpdates()
        motion.stopGyroUpdates()
        motion.stopMagnetometerUpdates()
        motion.stopDeviceMotionUpdates()
    }

    // MARK: - Signal Builders

    private static func signals(
        category: SignalCategory,
        motion: CMMotionManager,
        frame: CMAttitudeReferenceFrame?
    ) -> [FingerprintSignal] {
        var signals: [FingerprintSignal] = []

        if let acceleration = motion.accelerometerData?.acceleration {
            signals.append(
                .make(
                    "accelerometer",
                    category: category,
                    name: String(localized: "Accelerometer (g)", comment: "Signal card name in the Device Motion category — raw accelerometer reading (3-axis, in g)."),
                    value: format(x: acceleration.x, y: acceleration.y, z: acceleration.z),
                    rationale: accelerometerRationale,
                    displayHint: .axis,
                    entries: axisEntries(x: acceleration.x, y: acceleration.y, z: acceleration.z)))
        }

        if let rate = motion.gyroData?.rotationRate {
            signals.append(
                .make(
                    "gyroscope",
                    category: category,
                    name: String(localized: "Gyroscope, raw (rad/s)", comment: "Signal card name in the Device Motion category — raw gyroscope reading (3-axis, in rad/s)."),
                    value: format(x: rate.x, y: rate.y, z: rate.z),
                    rationale: gyroRationale,
                    displayHint: .axis,
                    entries: axisEntries(x: rate.x, y: rate.y, z: rate.z)))
        }

        if let field = motion.magnetometerData?.magneticField {
            signals.append(
                .make(
                    "magnetometer",
                    category: category,
                    name: String(localized: "Magnetometer, raw (µT)", comment: "Signal card name in the Device Motion category — raw magnetometer reading (3-axis, in microtesla)."),
                    value: format(x: field.x, y: field.y, z: field.z, decimals: 2),
                    rationale: magnetometerRationale,
                    displayHint: .axis,
                    entries: axisEntries(x: field.x, y: field.y, z: field.z, decimals: 2)))
        }

        if let dm = motion.deviceMotion {
            signals.append(contentsOf: deviceMotionSignals(from: dm, frame: frame, category: category))
        }

        return signals
    }

    private static func deviceMotionSignals(
        from sample: CMDeviceMotion,
        frame: CMAttitudeReferenceFrame?,
        category: SignalCategory
    ) -> [FingerprintSignal] {
        var signals: [FingerprintSignal] = []

        let attitude = sample.attitude
        let roll = attitude.roll * 180 / .pi
        let pitch = attitude.pitch * 180 / .pi
        let yaw = attitude.yaw * 180 / .pi
        signals.append(
            .make(
                "attitude",
                category: category,
                name: String(localized: "Attitude (°)", comment: "Signal card name in the Device Motion category — fused device orientation as roll, pitch, yaw in degrees."),
                value: String(format: "r=%+.2f  p=%+.2f  y=%+.2f", roll, pitch, yaw),
                rationale: attitudeRationale,
                displayHint: .axis,
                entries: [
                    SignalEntry(label: String(localized: "Roll", comment: "Attitude sub-label in the Device Motion category — roll axis in degrees."), value: String(format: "%+.2f", roll)),
                    SignalEntry(label: String(localized: "Pitch", comment: "Attitude sub-label in the Device Motion category — pitch axis in degrees."), value: String(format: "%+.2f", pitch)),
                    SignalEntry(label: String(localized: "Yaw", comment: "Attitude sub-label in the Device Motion category — yaw axis in degrees."), value: String(format: "%+.2f", yaw)),
                ]))

        let gravity = sample.gravity
        signals.append(
            .make(
                "gravity",
                category: category,
                name: String(localized: "Gravity (g)", comment: "Signal card name in the Device Motion category — gravity vector in g, separated from user-induced acceleration."),
                value: format(x: gravity.x, y: gravity.y, z: gravity.z),
                rationale: gravityRationale,
                displayHint: .axis,
                entries: axisEntries(x: gravity.x, y: gravity.y, z: gravity.z)))

        let userAccel = sample.userAcceleration
        signals.append(
            .make(
                "userAcceleration",
                category: category,
                name: String(localized: "User acceleration (g)", comment: "Signal card name in the Device Motion category — acceleration in g with gravity removed."),
                value: format(x: userAccel.x, y: userAccel.y, z: userAccel.z),
                rationale: userAccelRationale,
                displayHint: .axis,
                entries: axisEntries(x: userAccel.x, y: userAccel.y, z: userAccel.z)))

        let rotation = sample.rotationRate
        signals.append(
            .make(
                "rotationRateFused",
                category: category,
                name: String(localized: "Rotation rate, bias-corrected (rad/s)", comment: "Signal card name in the Device Motion category — bias-corrected rotation rate in rad/s from CMDeviceMotion."),
                value: format(x: rotation.x, y: rotation.y, z: rotation.z),
                rationale: rotationFusedRationale,
                displayHint: .axis,
                entries: axisEntries(x: rotation.x, y: rotation.y, z: rotation.z)))

        guard isNorthAligned(frame) else { return signals }

        let field = sample.magneticField
        var calEntries = axisEntries(x: field.field.x, y: field.field.y, z: field.field.z, decimals: 2)
        calEntries.append(SignalEntry(label: String(localized: "Acc", comment: "Magnetic-field sub-label in the Device Motion category — abbreviation for calibration accuracy."), value: String(field.accuracy.rawValue)))
        signals.append(
            .make(
                "magneticFieldCalibrated",
                category: category,
                name: String(localized: "Magnetic field, calibrated (µT)", comment: "Signal card name in the Device Motion category — calibrated 3-axis magnetic field in microtesla with accuracy indicator."),
                value: format(x: field.field.x, y: field.field.y, z: field.field.z, decimals: 2)
                    + String(format: "  acc=%d", field.accuracy.rawValue),
                rationale: calibratedMagRationale,
                displayHint: .axis,
                entries: calEntries))

        signals.append(
            .make(
                "heading",
                category: category,
                name: String(localized: "Compass heading", comment: "Signal card name in the Device Motion category — compass bearing in degrees relative to magnetic north."),
                value: String(format: "%.1f°", sample.heading),
                rationale: headingRationale))

        return signals
    }

    private static func format(x: Double, y: Double, z: Double, decimals: Int = 4) -> String {
        String(format: "x=%+.\(decimals)f  y=%+.\(decimals)f  z=%+.\(decimals)f", x, y, z)
    }

    private static func axisEntries(x: Double, y: Double, z: Double, decimals: Int = 4) -> [SignalEntry] {
        [
            SignalEntry(label: "X", value: String(format: "%+.\(decimals)f", x)),
            SignalEntry(label: "Y", value: String(format: "%+.\(decimals)f", y)),
            SignalEntry(label: "Z", value: String(format: "%+.\(decimals)f", z)),
        ]
    }
}

#else // macOS

struct DeviceMotionProvider: SignalProvider {
    let category: SignalCategory = .deviceMotion

    func collect() async -> [FingerprintSignal] {
        [.make(
            "unavailable",
            category: category,
            name: String(localized: "Device Motion", comment: "Signal card name in the Device Motion category — placeholder shown on macOS where CoreMotion is unavailable."),
            value: String(localized: "Not available on macOS", comment: "Placeholder value shown when device motion is unavailable on this platform."),
            rationale: String(localized: "CoreMotion is an iOS-only framework.", comment: "Signal card rationale beneath the Device Motion placeholder on macOS."))]
    }
}
#endif
