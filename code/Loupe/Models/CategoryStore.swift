//
//  CategoryStore.swift
//  Loupe
//
//  Central observable state for the app. Owns every provider, the current
//  signal snapshot per category, and the permission states.
//

import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class CategoryStore {
    enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case denied(String)
    }

    private(set) var signals: [SignalCategory: [FingerprintSignal]] = [:]
    private(set) var loadStates: [SignalCategory: LoadState] = [:]
    private(set) var permissionStates: [PermissionKind: PermissionAuthorization] = [:]
    private(set) var liveCategories: Set<SignalCategory> = []

    private let providers: [SignalCategory: any SignalProvider]
    private var liveTasks: [SignalCategory: Task<Void, Never>] = [:]
    let permissionCenter: PermissionCenter

    /// When true, the store serves fixed fixtures and ignores all live
    /// collection so screenshots stay deterministic. See `ScreenshotMode`.
    private let isMock: Bool

    init() {
        let center = PermissionCenter()
        self.permissionCenter = center
        self.isMock = false

        var registry: [SignalCategory: any SignalProvider] = [:]
        let all: [any SignalProvider] = [
            DeviceIdentityProvider(),
            AppleAccountProvider(),
            SystemInfoProvider(),
            DisplayProvider(),
            LocaleProvider(),
            AccessibilityProvider(),
            DeviceMotionProvider(),
            BatteryProvider(),
            StorageProvider(),
            NetworkProvider(),
            FontsProvider(),
            VoicesProvider(),
            AppInfoProvider(),
            PasteboardProvider(),
            AudioRouteProvider(),
            MetalProvider(),
            TelephonyProvider(),
            InstalledAppsProvider(),
            WebViewFingerprintProvider(),
            PreviousInstallsProvider(),
            MotionProvider(center: center),
            LocationProvider(center: center),
            CameraProvider(center: center),
            BluetoothProvider(center: center),
            LocalNetworkProvider(center: center),
            ContactsProvider(center: center),
            PhotosProvider(center: center),
            CalendarProvider(center: center),
            RemindersProvider(center: center),
            MusicLibraryProvider(center: center),
        ]
        for provider in all {
            if registry[provider.category] != nil {
                assertionFailure("Duplicate provider for \(provider.category.rawValue)")
            }
            registry[provider.category] = provider
        }
        let missing = Set(SignalCategory.allCases).subtracting(registry.keys)
        assert(missing.isEmpty, "Missing providers for: \(missing.map(\.rawValue).joined(separator: ", "))")
        self.providers = registry

        for category in SignalCategory.allCases {
            loadStates[category] = .idle
        }
    }

    /// Builds a store pre-populated with fixed mock signals for every
    /// category. Used only for App Store screenshot capture. No providers
    /// are registered, so live collection and permission prompts never fire.
    init(mockSignals: [SignalCategory: [FingerprintSignal]]) {
        self.permissionCenter = PermissionCenter()
        self.providers = [:]
        self.isMock = true
        for category in SignalCategory.allCases {
            signals[category] = mockSignals[category] ?? []
            loadStates[category] = .loaded
        }
    }

    // MARK: - Accessors

    func signals(for category: SignalCategory) -> [FingerprintSignal] {
        signals[category] ?? []
    }

    func loadState(for category: SignalCategory) -> LoadState {
        loadStates[category] ?? .idle
    }

    func count(for category: SignalCategory) -> Int {
        signals(for: category).count
    }

    func categories(for sensitivity: Sensitivity) -> [SignalCategory] {
        SignalCategory.allCases.filter { $0.sensitivity == sensitivity }
    }

    // MARK: - Collection

    /// Refreshes every passive category in parallel. Permission-gated and
    /// advanced categories are loaded on demand so the home screen never
    /// triggers a consent prompt by accident.
    func refreshPassive() async {
        guard !isMock else { return }
        let passive = categories(for: .passive)
        await withTaskGroup(of: Void.self) { group in
            for category in passive {
                group.addTask { [weak self] in
                    await self?.refresh(category: category)
                }
            }
        }
    }

    func refresh(category: SignalCategory) async {
        guard !isMock else { return }
        guard let provider = providers[category] else { return }
        loadStates[category] = .loading
        let collected = await provider.collect()
        guard !Task.isCancelled else { return }
        signals[category] = collected
        loadStates[category] = .loaded
    }

    // MARK: - Permissioned collection

    func enableAndRefresh(category: SignalCategory) async {
        guard !isMock else { return }
        if await requestPermission(for: category) {
            await refresh(category: category)
        }
    }

    /// Requests the category's permission and records the outcome.
    /// Returns true when the resulting authorization is usable. Categories
    /// without a permission are always usable.
    func requestPermission(for category: SignalCategory) async -> Bool {
        guard !isMock else { return false }
        guard let permission = category.permission else { return true }
        loadStates[category] = .loading
        let authorization = await permissionCenter.request(permission)
        permissionStates[permission] = authorization
        if authorization.isUsable {
            return true
        } else {
            signals[category] = []
            loadStates[category] = .denied(authorization.displayName)
            return false
        }
    }

    // MARK: - Live streaming

    func isLive(_ category: SignalCategory) -> Bool {
        liveCategories.contains(category)
    }

    func supportsLive(_ category: SignalCategory) -> Bool {
        providers[category] is any LiveSignalProvider
    }

    func startLive(category: SignalCategory) {
        guard liveTasks[category] == nil,
              let provider = providers[category] as? any LiveSignalProvider else { return }
        liveCategories.insert(category)
        let stream = provider.stream()
        liveTasks[category] = Task { @MainActor [weak self] in
            for await snapshot in stream {
                guard !Task.isCancelled else { break }
                self?.signals[category] = snapshot
            }
            self?.liveCategories.remove(category)
        }
    }

    func stopLive(category: SignalCategory) {
        liveTasks[category]?.cancel()
        liveTasks.removeValue(forKey: category)
        liveCategories.remove(category)
    }

    // MARK: - Export

    /// Flat snapshot of every signal currently collected, used for export.
    func allSignalsSnapshot() -> [SignalCategory: [FingerprintSignal]] {
        Dictionary(uniqueKeysWithValues: SignalCategory.allCases.map { category in
            (category, signals[category] ?? [])
        })
    }

    /// Total count of signals currently loaded across all categories.
    var totalSignalCount: Int {
        signals.values.reduce(0) { $0 + $1.count }
    }
}
