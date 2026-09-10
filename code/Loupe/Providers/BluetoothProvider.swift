//
//  BluetoothProvider.swift
//  Loupe
//
//  Relies on the CBCentralManager that the PermissionCenter creates on
//  demand. Reports the names of nearby BLE peripherals discovered during
//  a brief scan.
//

import CoreBluetooth

@MainActor
struct BluetoothProvider: SignalProvider {
    let category: SignalCategory = .bluetooth
    let center: PermissionCenter

    func collect() async -> [FingerprintSignal] {
        guard let central = center.bluetoothCentral,
              central.state == .poweredOn else {
            return [
                .make(
                    "peripherals",
                    category: category,
                    name: String(localized: "BLE peripherals (5s scan)", comment: "Signal card name in the Bluetooth category — names and signal strength of BLE peripherals found during a 5-second scan."),
                    value: String(localized: "Bluetooth unavailable", comment: "Placeholder value in the Bluetooth category shown when Bluetooth is powered off or unavailable."),
                    rationale: String(localized: "BLE device names and signal strength discovered during a brief scan.", comment: "Signal card rationale beneath the BLE peripherals value."))
            ]
        }

        let sampler = BluetoothSampler(central: central)
        let devices = await sampler.sweep(duration: 5.0)
        let value = devices.isEmpty ? "None" : devices.map { "\($0.name) (\($0.rssi) dBm)" }.joined(separator: "\n")
        let entries: [SignalEntry]? = devices.isEmpty ? nil : devices.map {
            SignalEntry(label: $0.name, value: "\($0.rssi) dBm")
        }
        return [
            .make(
                "peripherals",
                category: category,
                name: String(localized: "BLE peripherals (5s scan)", comment: "Signal card name in the Bluetooth category — names and signal strength of BLE peripherals found during a 5-second scan."),
                value: value,
                rationale: String(localized: "BLE device names and signal strength discovered during a brief scan.", comment: "Signal card rationale beneath the BLE peripherals value."),
                displayHint: devices.isEmpty ? .plain : .keyValue,
                entries: entries)
        ]
    }
}

struct DiscoveredPeripheral {
    let name: String
    let rssi: Int
}

@MainActor
final class BluetoothSampler: NSObject, CBCentralManagerDelegate {
    private let central: CBCentralManager
    private var discovered: [String: DiscoveredPeripheral] = [:]
    private var pending: CheckedContinuation<[DiscoveredPeripheral], Never>?
    private var priorDelegate: (any CBCentralManagerDelegate)?
    private var timeoutTask: Task<Void, Never>?

    init(central: CBCentralManager) {
        self.central = central
        super.init()
    }

    func sweep(duration: TimeInterval) async -> [DiscoveredPeripheral] {
        await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<[DiscoveredPeripheral], Never>) in
                beginSweep(duration: duration, continuation: continuation)
            }
        } onCancel: {
            Task { @MainActor in
                self.finishSweep()
            }
        }
    }

    private func beginSweep(
        duration: TimeInterval,
        continuation: CheckedContinuation<[DiscoveredPeripheral], Never>
    ) {
        guard pending == nil else {
            continuation.resume(returning: sortedResults())
            return
        }
        pending = continuation
        priorDelegate = central.delegate
        central.delegate = self
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        timeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            self?.finishSweep()
        }
    }

    private func finishSweep() {
        guard let pending else { return }
        timeoutTask?.cancel()
        timeoutTask = nil
        central.stopScan()
        central.delegate = priorDelegate
        priorDelegate = nil
        let results = sortedResults()
        discovered.removeAll()
        self.pending = nil
        pending.resume(returning: results)
    }

    private func sortedResults() -> [DiscoveredPeripheral] {
        discovered.values.sorted { $0.rssi > $1.rssi }
    }

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {}

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let id = peripheral.identifier.uuidString
        let name = peripheral.name
            ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? id
        let rssi = RSSI.intValue
        Task { @MainActor in self.discovered[id] = DiscoveredPeripheral(name: name, rssi: rssi) }
    }
}
