//
//  DisplayProvider.swift
//  Loupe
//
//  Everything a screen and its trait collection can reveal: physical
//  pixels, DPR, refresh ceiling, HDR support, dynamic type size, and
//  a per-device safe-area signature.
//

import SwiftUI

final class DisplayProvider: SignalProvider, LiveSignalProvider {
    let category: SignalCategory = .display
    let updateInterval: TimeInterval = 1.0

    func collect() async -> [FingerprintSignal] {
        await buildSignals()
    }

    func stream() -> AsyncStream<[FingerprintSignal]> {
        AsyncStream { continuation in
            let task = Task { @MainActor [weak self] in
                guard let self else { continuation.finish(); return }
                continuation.yield(await self.buildSignals())
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: UInt64(self.updateInterval * 1_000_000_000))
                    if Task.isCancelled { break }
                    continuation.yield(await self.buildSignals())
                }
                continuation.finish()
            }
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }

    private func buildSignals() async -> [FingerprintSignal] {
        guard let info = PlatformScreen.displayInfo() else {
            return [
                .make(
                    "unavailable",
                    category: category,
                    name: String(localized: "Display", comment: "Signal card name in the Display category — placeholder shown when no active window scene is available."),
                    value: String(localized: "No active window scene", comment: "Placeholder value shown when display attributes are unavailable because the app is not attached to a scene."),
                    rationale: String(localized: "Display attributes are unavailable because the app is not attached to a scene.", comment: "Signal card rationale beneath the Display placeholder."))
            ]
        }

        var signals: [FingerprintSignal] = []

        signals.append(
            .make(
                "nativeBounds",
                category: category,
                name: String(localized: "Native bounds", comment: "Signal card name in the Display category — physical pixel dimensions of the screen."),
                value: "\(Int(info.nativeBounds.width))x\(Int(info.nativeBounds.height))",
                rationale: String(localized: "The screen's physical pixel dimensions.", comment: "Signal card rationale beneath the Native bounds value.")))
        signals.append(
            .make(
                "scale",
                category: category,
                name: String(localized: "scale", comment: "Signal card name in the Display category — UIScreen.scale (point-to-pixel ratio)."),
                value: String(format: "%.2f", info.scale),
                rationale: String(localized: "Point-to-pixel ratio (the canonical @2x / @3x value).", comment: "Signal card rationale beneath the scale value.")))
        signals.append(
            .make(
                "nativeScale",
                category: category,
                name: String(localized: "nativeScale", comment: "Signal card name in the Display category — UIScreen.nativeScale (actual downscale ratio)."),
                value: String(format: "%.4f", info.nativeScale),
                rationale: String(localized: "Actual downscale ratio. Differs from `scale` on Plus/Pro Max models.", comment: "Signal card rationale beneath the nativeScale value.")))
        signals.append(
            .make(
                "maxFPS",
                category: category,
                name: String(localized: "Max frames per second", comment: "Signal card name in the Display category — UIScreen.maximumFramesPerSecond (display refresh rate ceiling)."),
                value: String(info.maximumFramesPerSecond),
                rationale: String(localized: "60 Hz on most devices, 120 Hz on ProMotion displays.", comment: "Signal card rationale beneath the Max frames per second value.")))
        if info.brightness >= 0 {
            signals.append(
                .make(
                    "brightness",
                    category: category,
                    name: String(localized: "Brightness", comment: "Signal card name in the Display category — current screen brightness level."),
                    value: String(format: "%.2f", info.brightness),
                    rationale: String(localized: "Current screen brightness (0.0 to 1.0). Changes with your adjustments and ambient light.", comment: "Signal card rationale beneath the Brightness value.")))
        }
        signals.append(
            .make(
                "displayGamut",
                category: category,
                name: String(localized: "displayGamut", comment: "Signal card name in the Display category — UITraitCollection.displayGamut (sRGB or P3)."),
                value: info.displayGamut,
                rationale: String(localized: "sRGB or P3. Newer displays support P3.", comment: "Signal card rationale beneath the displayGamut value.")))
        signals.append(
            .make(
                "sizeClass",
                category: category,
                name: String(localized: "Size class", comment: "Signal card name in the Display category — horizontal × vertical size class (UITraitCollection)."),
                value: "\(info.horizontalSizeClass) × \(info.verticalSizeClass)",
                rationale: String(localized: "Compact vs regular in each axis. Varies by device type and orientation.", comment: "Signal card rationale beneath the Size class value."),
                displayHint: .compound,
                entries: [
                    SignalEntry(label: String(localized: "Horizontal", comment: "Size-class sub-label. Apple's UITraitCollection horizontal size-class axis."), value: info.horizontalSizeClass),
                    SignalEntry(label: String(localized: "Vertical", comment: "Size-class sub-label. Apple's UITraitCollection vertical size-class axis."), value: info.verticalSizeClass),
                ]))
        signals.append(
            .make(
                "preferredContentSizeCategory",
                category: category,
                name: String(localized: "preferredContentSizeCategory", comment: "Signal card name in the Display category — UITraitCollection.preferredContentSizeCategory (Dynamic Type size)."),
                value: info.preferredContentSizeCategory,
                rationale: String(localized: "Dynamic Type size: the text-size preference you've set in Settings.", comment: "Signal card rationale beneath the preferredContentSizeCategory value.")))
        let insets = info.safeAreaInsets
        signals.append(
            .make(
                "safeAreaInsets",
                category: category,
                name: String(localized: "safeAreaInsets", comment: "Signal card name in the Display category — UIWindow.safeAreaInsets (notch / Dynamic Island shape)."),
                value: "top=\(insets.top) left=\(insets.left) bottom=\(insets.bottom) right=\(insets.right)",
                rationale: String(localized: "Inset values shaped by the notch or Dynamic Island. Varies by device chassis.", comment: "Signal card rationale beneath the safeAreaInsets value."),
                displayHint: .keyValue,
                entries: [
                    SignalEntry(label: String(localized: "top", comment: "Safe-area sub-label in the Display category — top inset."), value: "\(insets.top)"),
                    SignalEntry(label: String(localized: "left", comment: "Safe-area sub-label in the Display category — left inset."), value: "\(insets.left)"),
                    SignalEntry(label: String(localized: "bottom", comment: "Safe-area sub-label in the Display category — bottom inset."), value: "\(insets.bottom)"),
                    SignalEntry(label: String(localized: "right", comment: "Safe-area sub-label in the Display category — right inset."), value: "\(insets.right)"),
                ]))
        return signals
    }
}
