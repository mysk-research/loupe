//
//  MetalProvider.swift
//  Loupe
//
//  The GPU answer from MTLCreateSystemDefaultDevice is a near-perfect
//  SoC classifier. Feature set flags split Apple A-series generations
//  and identify iPad Pro / Vision hardware.
//

import Foundation
import Metal

struct MetalProvider: SignalProvider {
    let category: SignalCategory = .metal

    func collect() async -> [FingerprintSignal] {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return [
                .make(
                    "unavailable",
                    category: category,
                    name: String(localized: "Metal", comment: "Signal card name in the Graphics & Metal category — placeholder shown when no default Metal device is available (e.g., simulator)."),
                    value: String(localized: "No default device", comment: "Placeholder value in the Graphics & Metal category shown when no default Metal device is available (e.g., simulator)."),
                    rationale: String(localized: "The simulator may not report a Metal GPU.", comment: "Signal card rationale beneath the Metal placeholder."))
            ]
        }
        var signals: [FingerprintSignal] = []

        signals.append(
            .make(
                "name",
                category: category,
                name: String(localized: "GPU name", comment: "Signal card name in the Graphics & Metal category — MTLDevice.name."),
                value: device.name,
                rationale: String(localized: "GPU name as Metal reports it (e.g., `Apple A18 Pro GPU`).", comment: "Signal card rationale beneath the GPU name value.")))
        signals.append(
            .make(
                "recommendedMax",
                category: category,
                name: String(localized: "Recommended max working set", comment: "Signal card name in the Graphics & Metal category — MTLDevice.recommendedMaxWorkingSetSize."),
                value: ByteCountFormatter.string(fromByteCount: Int64(device.recommendedMaxWorkingSetSize), countStyle: .memory),
                rationale: String(localized: "How much GPU memory the system suggests apps target.", comment: "Signal card rationale beneath the Recommended max working set value.")))
        signals.append(
            .make(
                "raytracing",
                category: category,
                name: String(localized: "Supports raytracing", comment: "Signal card name in the Graphics & Metal category — MTLDevice.supportsRaytracing."),
                value: String(device.supportsRaytracing),
                rationale: String(localized: "Whether your \(PlatformDevice.localizedModel)'s GPU supports hardware ray tracing.", comment: "Signal card rationale beneath the Supports raytracing value. %@ is the device model name (e.g., iPhone, iPad).")))

        let families: [MTLGPUFamily] = [.apple1, .apple2, .apple3, .apple4, .apple5, .apple6, .apple7, .apple8, .apple9, .common1, .common2, .common3, .metal3]
        let supported = families.filter { device.supportsFamily($0) }.map(describe)
        signals.append(
            .make(
                "families",
                category: category,
                name: String(localized: "Supported families", comment: "Signal card name in the Graphics & Metal category — list of MTLGPUFamily values this hardware supports."),
                value: supported.joined(separator: ", "),
                rationale: String(localized: "Metal GPU families this hardware supports.", comment: "Signal card rationale beneath the Supported families value."),
                displayHint: supported.isEmpty ? .plain : .tags,
                entries: supported.isEmpty ? nil : supported.map { SignalEntry(label: $0, value: "") }))
        return signals
    }

    private func describe(_ family: MTLGPUFamily) -> String {
        switch family {
        case .apple1: return "apple1"
        case .apple2: return "apple2"
        case .apple3: return "apple3"
        case .apple4: return "apple4"
        case .apple5: return "apple5"
        case .apple6: return "apple6"
        case .apple7: return "apple7"
        case .apple8: return "apple8"
        case .apple9: return "apple9"
        case .common1: return "common1"
        case .common2: return "common2"
        case .common3: return "common3"
        case .metal3: return "metal3"
        default: return "family(\(family.rawValue))"
        }
    }
}
