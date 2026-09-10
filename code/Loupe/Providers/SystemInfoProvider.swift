//
//  SystemInfoProvider.swift
//  Loupe
//
//  ProcessInfo + sysctl kernel state. This is arguably the most potent
//  passive category because it includes kernel build version and boot
//  time, which together rarely collide across devices.
//

import Foundation

struct SystemInfoProvider: SignalProvider {
    let category: SignalCategory = .systemInfo

    func collect() async -> [FingerprintSignal] {
        let info = ProcessInfo.processInfo
        var signals: [FingerprintSignal] = []

        signals.append(
            .make(
                "processorCount",
                category: category,
                name: String(localized: "Processor count", comment: "Signal card name in the System Info category — ProcessInfo.processorCount."),
                value: String(info.processorCount),
                rationale:
                    String(localized: "Number of CPU cores visible to apps. Can fluctuate with thermal throttling.", comment: "Signal card rationale beneath the Processor count value.")))
        signals.append(
            .make(
                "physicalMemory",
                category: category,
                name: String(localized: "Physical memory", comment: "Signal card name in the System Info category — ProcessInfo.physicalMemory (total RAM)."),
                value: formatBytes(Int64(info.physicalMemory)),
                rationale: String(localized: "Total RAM on your \(PlatformDevice.localizedModel).", comment: "Signal card rationale beneath the Physical memory value. %@ is the device model name (e.g., iPhone, iPad).")))
        signals.append(
            .make(
                "operatingSystem",
                category: category,
                name: String(localized: "OS version string", comment: "Signal card name in the System Info category — ProcessInfo.operatingSystemVersionString."),
                value: info.operatingSystemVersionString,
                rationale: String(localized: "The full \(PlatformDevice.systemName) version string the system reports.", comment: "Signal card rationale beneath the OS version string value. %@ is the OS name (iOS, iPadOS, macOS).")))
        if let kernVersion = SysctlHelper.string("kern.version") {
            signals.append(
                .make(
                    "kern.version",
                    category: category,
                    name: String(localized: "kern.version", comment: "Signal card name in the System Info category — the kern.version sysctl value (kernel build string)."),
                    value: kernVersion,
                    rationale:
                        String(localized: "The kernel version string, with build details and compiler timestamps.", comment: "Signal card rationale beneath the kern.version value.")))
        }
        if let boot = SysctlHelper.timeval("kern.boottime") {
            let bootDate = Date(timeIntervalSince1970: TimeInterval(boot.seconds))
            signals.append(
                .make(
                    "kern.boottime",
                    category: category,
                    name: String(localized: "Boot time", comment: "Signal card name in the System Info category — the kern.boottime sysctl value (last boot timestamp)."),
                    value: ISO8601DateFormatter().string(from: bootDate),
                    rationale:
                        String(localized: "When your \(PlatformDevice.localizedModel) last booted. Stays the same until the next restart.", comment: "Signal card rationale beneath the Boot time value. %@ is the device model name (e.g., iPhone, iPad).")))
        }

        let lockdownEnabled = UserDefaults.standard.bool(forKey: "LDMGlobalEnabled")
        signals.append(
            .make(
                "lockdownMode",
                category: category,
                name: String(localized: "Lockdown Mode", comment: "Signal card name in the System Info category — whether Apple's Lockdown Mode is turned on."),
                value: lockdownEnabled ? String(localized: "Enabled", comment: "Lockdown Mode signal value in the System Info category — shown when Lockdown Mode is turned on.") : String(localized: "Not enabled", comment: "Lockdown Mode signal value in the System Info category — shown when Lockdown Mode is turned off."),
                rationale:
                    String(localized: "Whether you have \(PlatformDevice.systemName) Lockdown Mode turned on.", comment: "Signal card rationale beneath the Lockdown Mode value. %@ is the OS name (iOS, iPadOS, macOS).")
            ))

        return signals
    }

    private func formatBytes(_ count: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: count, countStyle: .memory)
    }
}
