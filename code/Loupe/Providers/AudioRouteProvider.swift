//
//  AudioRouteProvider.swift
//  Loupe
//
//  Audio route and device information. On iOS this comes from
//  AVAudioSession; on macOS from CoreAudio's HAL. Both populate the
//  same AudioSnapshot model so signal construction is shared.
//

@preconcurrency import AVFoundation

#if os(macOS)
import CoreAudio
#endif

// MARK: - Platform-neutral snapshot

private struct AudioSnapshot {
    struct Port {
        let type: String
        let name: String
    }
    var outputs: [Port] = []
    var inputs: [Port] = []
    var sampleRate: Double?
    var outputLatency: Double?
    var inputLatency: Double?
    var isOtherAudioPlaying: Bool?
    var outputVolume: Float?
    var outputChannels: Int?
    var inputChannels: Int?
    var allDeviceNames: [String] = []
}

// MARK: - Provider

final class AudioRouteProvider: SignalProvider, LiveSignalProvider {
    let category: SignalCategory = .audioRoute
    let updateInterval: TimeInterval = 0

    func collect() async -> [FingerprintSignal] {
        #if os(iOS)
        activateSession()
        #endif
        return buildSignals(from: currentSnapshot())
    }

    func stream() -> AsyncStream<[FingerprintSignal]> {
        AsyncStream { continuation in
            #if os(iOS)
            self.activateSession()
            continuation.yield(self.buildSignals(from: self.currentSnapshot()))

            let session = AVAudioSession.sharedInstance()
            let volumeObservation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, _ in
                guard let self else { return }
                Task { @MainActor in
                    continuation.yield(self.buildSignals(from: self.currentSnapshot()))
                }
            }
            let routeToken = NotificationCenter.default.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: session,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    continuation.yield(self.buildSignals(from: self.currentSnapshot()))
                }
            }
            nonisolated(unsafe) let token = routeToken
            continuation.onTermination = { @Sendable _ in
                volumeObservation.invalidate()
                NotificationCenter.default.removeObserver(token)
            }
            #else
            continuation.yield(self.buildSignals(from: self.currentSnapshot()))
            continuation.finish()
            #endif
        }
    }

    // MARK: - Shared signal builder

    private func buildSignals(from snap: AudioSnapshot) -> [FingerprintSignal] {
        var signals: [FingerprintSignal] = []

        let outputDesc = snap.outputs.map { "\($0.type):\($0.name)" }.joined(separator: ", ")
        let outputEntries: [SignalEntry]? = snap.outputs.isEmpty ? nil : snap.outputs.map {
            SignalEntry(label: $0.name, value: $0.type)
        }
        signals.append(.make(
            "outputs", category: category,
            name: String(localized: "Current outputs", comment: "Signal card name in the Audio category — currently routed audio output ports."),
            value: outputDesc.isEmpty ? "(none)" : outputDesc,
            rationale: String(localized: "Output ports and their names (e.g., paired AirPods, AirPlay receivers).", comment: "Signal card rationale beneath the Current outputs value."),
            displayHint: snap.outputs.isEmpty ? .plain : .keyValue,
            entries: outputEntries))

        let inputDesc = snap.inputs.map { "\($0.type):\($0.name)" }.joined(separator: ", ")
        let inputEntries: [SignalEntry]? = snap.inputs.isEmpty ? nil : snap.inputs.map {
            SignalEntry(label: $0.name, value: $0.type)
        }
        signals.append(.make(
            "inputs", category: category,
            name: String(localized: "Current inputs", comment: "Signal card name in the Audio category — currently routed audio input ports."),
            value: inputDesc.isEmpty ? "(none)" : inputDesc,
            rationale: String(localized: "Connected input hardware (built-in, headset, or accessory microphone).", comment: "Signal card rationale beneath the Current inputs value."),
            displayHint: snap.inputs.isEmpty ? .plain : .keyValue,
            entries: inputEntries))

        if let rate = snap.sampleRate {
            signals.append(.make(
                "sampleRate", category: category,
                name: String(localized: "Hardware sample rate", comment: "Signal card name in the Audio category — current hardware sample rate in Hz."),
                value: String(format: "%.0f Hz", rate),
                rationale: String(localized: "The current hardware sample rate.", comment: "Signal card rationale beneath the Hardware sample rate value.")))
        }

        if let outLat = snap.outputLatency, let inLat = snap.inputLatency {
            signals.append(.make(
                "latency", category: category,
                name: String(localized: "DAC / ADC latency (s)", comment: "Signal card name in the Audio category — digital-to-analog and analog-to-digital converter latency in seconds."),
                value: String(format: "out %.6f / in %.6f", outLat, inLat),
                rationale: String(localized: "DAC and ADC latency for the current audio route.", comment: "Signal card rationale beneath the DAC / ADC latency value."),
                displayHint: .compound,
                entries: [
                    SignalEntry(label: String(localized: "Output", comment: "Latency sub-label in the Audio category — output (DAC) latency in seconds."), value: String(format: "%.6f", outLat)),
                    SignalEntry(label: String(localized: "Input", comment: "Latency sub-label in the Audio category — input (ADC) latency in seconds."), value: String(format: "%.6f", inLat)),
                ]))
        }

        if let playing = snap.isOtherAudioPlaying {
            signals.append(.make(
                "otherAudioPlaying", category: category,
                name: String(localized: "Other audio playing", comment: "Signal card name in the Audio category — whether another app is currently playing audio."),
                value: String(playing),
                rationale: String(localized: "Whether another app is currently playing audio.", comment: "Signal card rationale beneath the Other audio playing value.")))
        }

        if let volume = snap.outputVolume {
            signals.append(.make(
                "outputVolume", category: category,
                name: String(localized: "Output volume", comment: "Signal card name in the Audio category — system output volume level."),
                value: String(format: "%.2f", volume),
                rationale: String(localized: "Current system output volume (0.0 to 1.0).", comment: "Signal card rationale beneath the Output volume value.")))
        }

        if let ch = snap.outputChannels {
            signals.append(.make(
                "outputChannels", category: category,
                name: String(localized: "Output channels", comment: "Signal card name in the Audio category — number of output channels on the default output device."),
                value: String(ch),
                rationale: String(localized: "Number of output channels on the default output device.", comment: "Signal card rationale beneath the Output channels value.")))
        }

        if let ch = snap.inputChannels {
            signals.append(.make(
                "inputChannels", category: category,
                name: String(localized: "Input channels", comment: "Signal card name in the Audio category — number of input channels on the default input device."),
                value: String(ch),
                rationale: String(localized: "Number of input channels on the default input device.", comment: "Signal card rationale beneath the Input channels value.")))
        }

        if !snap.allDeviceNames.isEmpty {
            let deviceEntries = snap.allDeviceNames.map { SignalEntry(label: $0, value: "") }
            signals.append(.make(
                "allDevices", category: category,
                name: String(localized: "All audio devices", comment: "Signal card name in the Audio category — complete list of audio devices visible to the system (macOS)."),
                value: "\(snap.allDeviceNames.count): \(snap.allDeviceNames.joined(separator: ", "))",
                rationale: String(localized: "Complete list of audio devices visible to the system.", comment: "Signal card rationale beneath the All audio devices value."),
                displayHint: .tags,
                entries: deviceEntries))
        }

        return signals
    }

    // MARK: - Platform snapshot factories

    private func currentSnapshot() -> AudioSnapshot {
        #if os(iOS)
        return iOSSnapshot()
        #else
        return macSnapshot()
        #endif
    }

    #if os(iOS)
    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: .mixWithOthers)
        try? session.setActive(true)
    }

    private func iOSSnapshot() -> AudioSnapshot {
        let session = AVAudioSession.sharedInstance()
        let route = session.currentRoute
        return AudioSnapshot(
            outputs: route.outputs.map { .init(type: $0.portType.rawValue, name: $0.portName) },
            inputs: route.inputs.map { .init(type: $0.portType.rawValue, name: $0.portName) },
            sampleRate: session.sampleRate,
            outputLatency: session.outputLatency,
            inputLatency: session.inputLatency,
            isOtherAudioPlaying: session.isOtherAudioPlaying,
            outputVolume: session.outputVolume
        )
    }
    #endif

    #if os(macOS)
    private func macSnapshot() -> AudioSnapshot {
        var snap = AudioSnapshot()

        if let outputID = defaultDevice(scope: kAudioObjectPropertyScopeOutput) {
            let name = deviceName(outputID) ?? "(unknown)"
            snap.outputs = [.init(type: "default", name: name)]
            snap.sampleRate = nominalSampleRate(outputID)
            snap.outputChannels = channelCount(outputID, scope: kAudioObjectPropertyScopeOutput)
            snap.outputVolume = masterVolume(outputID, scope: kAudioObjectPropertyScopeOutput)
        }

        if let inputID = defaultDevice(scope: kAudioObjectPropertyScopeInput) {
            let name = deviceName(inputID) ?? "(unknown)"
            snap.inputs = [.init(type: "default", name: name)]
            snap.inputChannels = channelCount(inputID, scope: kAudioObjectPropertyScopeInput)
        }

        snap.allDeviceNames = enumerateDevices().compactMap { deviceName($0) }
        return snap
    }

    // MARK: CoreAudio helpers

    private func defaultDevice(scope: AudioObjectPropertyScope) -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: scope == kAudioObjectPropertyScopeOutput
                ? kAudioHardwarePropertyDefaultOutputDevice
                : kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var deviceID: AudioDeviceID = kAudioObjectUnknown
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        return status == noErr && deviceID != kAudioObjectUnknown ? deviceID : nil
    }

    private func deviceName(_ deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var name: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &name)
        return status == noErr ? name as String : nil
    }

    private func nominalSampleRate(_ deviceID: AudioDeviceID) -> Double? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyNominalSampleRate,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var rate: Float64 = 0
        var size = UInt32(MemoryLayout<Float64>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &rate)
        return status == noErr && rate > 0 ? rate : nil
    }

    private func channelCount(_ deviceID: AudioDeviceID, scope: AudioObjectPropertyScope) -> Int? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size) == noErr, size > 0 else { return nil }
        let bufferListPtr = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(size) / MemoryLayout<AudioBufferList>.stride + 1)
        defer { bufferListPtr.deallocate() }
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, bufferListPtr) == noErr else { return nil }
        let bufferList = UnsafeMutableAudioBufferListPointer(bufferListPtr)
        return bufferList.reduce(0) { $0 + Int($1.mNumberChannels) }
    }

    private func masterVolume(_ deviceID: AudioDeviceID, scope: AudioObjectPropertyScope) -> Float? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain)
        guard AudioObjectHasProperty(deviceID, &address) else { return nil }
        var volume: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume)
        return status == noErr ? volume : nil
    }

    private func enumerateDevices() -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size) == noErr else { return [] }
        let count = Int(size) / MemoryLayout<AudioDeviceID>.size
        var devices = [AudioDeviceID](repeating: kAudioObjectUnknown, count: count)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &devices) == noErr else { return [] }
        return devices
    }
    #endif
}
