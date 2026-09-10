//
//  CollectionConsent.swift
//  Loupe
//
//  An app-level consent a category needs before part of its collection
//  may run, beyond the iOS permission — for example, sending photo
//  coordinates to Apple's geocoding service. The user's choice is
//  remembered in UserDefaults and surfaced as a toggle on the
//  category's screen.
//

import Foundation

struct CollectionConsent: Sendable {
    /// Defaults-key prefix, e.g. "photosGeocoding".
    let key: String
    /// Consent dialog title.
    let promptTitle: String
    /// Consent dialog body.
    let promptMessage: String
    /// Consent dialog button that grants the consent.
    let acceptLabel: String
    /// Consent dialog button that declines the consent.
    let declineLabel: String
    /// Label of the toggle shown on the category's screen.
    let toggleLabel: String
    /// SF Symbol shown next to the toggle.
    let toggleSymbol: String
    /// Explanatory copy shown beneath the toggle.
    let toggleFooter: String

    var enabledKey: String { key + "Enabled" }
    var respondedKey: String { key + "Responded" }

    /// Whether the user has granted this consent.
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        nonmutating set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    /// Whether the user has answered the consent dialog (or made a manual
    /// choice via the toggle), so the dialog is never shown again.
    var hasResponded: Bool {
        get { UserDefaults.standard.bool(forKey: respondedKey) }
        nonmutating set { UserDefaults.standard.set(newValue, forKey: respondedKey) }
    }
}

extension CollectionConsent {
    /// Photos place-name lookup via Apple's geocoding service.
    static let photosGeocoding = CollectionConsent(
        key: "photosGeocoding",
        promptTitle: String(localized: "Look up place names?", comment: "Title of the consent dialog shown after granting Photos access, asking whether Loupe may turn photo coordinates into place names using an Apple service."),
        promptMessage: String(localized: "Loupe can turn the geotags in your photos into place names using an Apple service. Only the raw coordinates are sent, never your photos. You can change this anytime with the switch on this screen.", comment: "Body of the consent dialog shown after granting Photos access, explaining that reverse geocoding sends coordinates to Apple."),
        acceptLabel: String(localized: "Look Up Places", comment: "Consent dialog button that allows turning photo coordinates into place names using an Apple service."),
        declineLabel: String(localized: "Skip", comment: "Consent dialog button that declines turning photo coordinates into place names."),
        toggleLabel: String(localized: "Look Up Place Names", comment: "Label of the toggle on the Photos screen that controls whether photo coordinates are turned into place names using an Apple service."),
        toggleSymbol: "mappin.and.ellipse",
        toggleFooter: String(localized: "Loupe turns the geotags in your photos into place names using an Apple service. Only the raw coordinates are sent, never your photos.", comment: "Footer text beneath the place-name lookup toggle on the Photos screen."))
}
