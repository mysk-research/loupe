//
//  Compatibility.swift
//  Loupe
//
//  Compatibility wrappers for newer SwiftUI APIs so feature views can
//  keep using one call site while preserving older OS support.
//

import SwiftUI

extension View {
    @ViewBuilder
    func compatibleBorderedButtonStyle() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    func compatibleProminentButtonStyle() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    func compatibleRotateSymbolEffect<Value: Equatable>(value: Value) -> some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            symbolEffect(.rotate, value: value)
        } else {
            self
        }
    }

    @ViewBuilder
    func compatibleScrollEdgeStyleSoft() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            scrollEdgeEffectStyle(.soft, for: .all)
        } else {
            self
        }
    }

    /// Marks this view as the source of a zoom transition when the matching
    /// destination is presented. No-op below iOS 18 and on platforms where
    /// the zoom navigation transition is unavailable (e.g. macOS).
    @ViewBuilder
    func compatibleZoomTransitionSource<ID: Hashable>(id: ID, in namespace: Namespace.ID) -> some View {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
        #else
        self
        #endif
    }

    /// Applies a zoom navigation transition originating from the matching
    /// source view. No-op below iOS 18 and on platforms where the zoom
    /// navigation transition is unavailable (e.g. macOS).
    @ViewBuilder
    func compatibleZoomNavigationTransition<ID: Hashable>(sourceID: ID, in namespace: Namespace.ID) -> some View {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            self
        }
        #else
        self
        #endif
    }
}
