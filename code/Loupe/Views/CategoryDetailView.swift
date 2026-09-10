//
//  CategoryDetailView.swift
//  Loupe
//
//  The per-category screen. For permissioned categories it hosts a
//  gate view until the user has granted access, then it turns into
//  a signal list.
//

import SwiftUI

struct CategoryDetailView: View {
    let category: SignalCategory
    @Bindable var store: CategoryStore

    @State private var showConsentPrompt = false

    var body: some View {
        let loadState = store.loadState(for: category)
        let signals = store.signals(for: category)

        Group {
            if shouldShowGate(loadState: loadState) {
                PermissionGateView(
                    category: category,
                    loadState: loadState,
                    onEnable: { Task { await enableAndRefresh() } }
                )
            } else {
                signalList(signals: signals)
            }
        }
        .navigationTitle(category.title)
        .toolbarTitleDisplayMode(.inline)
        .toolbar { toolbarContent(loadState: loadState) }
        .alert(
            category.collectionConsent?.promptTitle ?? "",
            isPresented: $showConsentPrompt
        ) {
            if let consent = category.collectionConsent {
                Button(consent.acceptLabel) {
                    respond(to: consent, accepted: true)
                }
                Button(consent.declineLabel, role: .cancel) {
                    respond(to: consent, accepted: false)
                }
            }
        } message: {
            Text(category.collectionConsent?.promptMessage ?? "")
        }
        .task {
            if category.sensitivity != .permissioned, loadState == .idle {
                await store.refresh(category: category)
            }
            updateLiveCollection()
        }
        .onChange(of: loadState) {
            updateLiveCollection()
        }
        .onDisappear {
            store.stopLive(category: category)
        }
    }

    @ToolbarContentBuilder
    private func toolbarContent(loadState: CategoryStore.LoadState) -> some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            HStack(spacing: 12) {
                if store.isLive(category) {
                    LiveIndicator()
                }
                Button {
                    Task {
                        if category.sensitivity == .permissioned {
                            await enableAndRefresh()
                        } else {
                            await store.refresh(category: category)
                        }
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .compatibleRotateSymbolEffect(value: loadState == .loading)
                }
                .disabled(loadState == .loading)
            }
        }
    }

    private func signalList(signals: [FingerprintSignal]) -> some View {
        List {
            Section {
                ForEach(signals) { signal in
                    SignalRowView(signal: signal)
                }
            } header: {
                header(signalCount: signals.count)
                    .textCase(nil)
            } footer: {
                Text(category.sensitivity.blurb)
                    .font(.caption)
            }
            if let consent = category.collectionConsent {
                ConsentToggleSection(consent: consent, onEnable: {
                    Task { await store.refresh(category: category) }
                })
            }
        }
        .platformInsetGroupedListStyle()
    }

    private func header(signalCount: Int) -> some View {
        VStack(alignment: .leading) {
            Label(category.sensitivity.title, systemImage: category.sensitivity.symbolName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(category.sensitivity.tint)
            Text(category.subtitle)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    /// Enables a permissioned category. If the category asks for an
    /// app-level consent that hasn't been answered yet, a one-time dialog
    /// is shown before the first collection.
    private func enableAndRefresh() async {
        guard let consent = category.collectionConsent, !consent.hasResponded else {
            await store.enableAndRefresh(category: category)
            return
        }
        if await store.requestPermission(for: category) {
            showConsentPrompt = true
        }
    }

    private func respond(to consent: CollectionConsent, accepted: Bool) {
        consent.isEnabled = accepted
        consent.hasResponded = true
        Task { await store.refresh(category: category) }
    }

    private func shouldShowGate(loadState: CategoryStore.LoadState) -> Bool {
        guard category.sensitivity == .permissioned else { return false }
        switch loadState {
        case .loaded: return false
        default: return true
        }
    }

    private func updateLiveCollection() {
        guard store.supportsLive(category) else { return }
        if shouldShowGate(loadState: store.loadState(for: category)) {
            store.stopLive(category: category)
        } else {
            store.startLive(category: category)
        }
    }
}

// MARK: - Consent Toggle

/// List section with a toggle for a category's app-level consent.
/// Turning it on triggers a fresh collection right away. Turning it off
/// keeps the values already on screen and only affects the next refresh.
private struct ConsentToggleSection: View {
    let consent: CollectionConsent
    let onEnable: () -> Void

    @AppStorage private var isEnabled: Bool

    init(consent: CollectionConsent, onEnable: @escaping () -> Void) {
        self.consent = consent
        self.onEnable = onEnable
        _isEnabled = AppStorage(wrappedValue: false, consent.enabledKey)
    }

    var body: some View {
        Section {
            Toggle(isOn: $isEnabled) {
                Label(consent.toggleLabel, systemImage: consent.toggleSymbol)
            }
        } footer: {
            Text(consent.toggleFooter)
                .font(.caption)
        }
        .onChange(of: isEnabled) {
            consent.hasResponded = true
            if isEnabled {
                onEnable()
            }
        }
    }
}

// MARK: - Live Indicator

private struct LiveIndicator: View {
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.red)
                .frame(width: 7, height: 7)
                .phaseAnimator([false, true]) { circle, pulsing in
                    circle
                        .scaleEffect(pulsing ? 1.3 : 1.0)
                        .opacity(pulsing ? 0.7 : 1.0)
                } animation: { _ in
                    .easeInOut(duration: 0.8)
                }
            Text("LIVE")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.red)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Live updates")
    }
}
