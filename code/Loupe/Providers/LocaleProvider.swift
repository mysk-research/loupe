//
//  LocaleProvider.swift
//  Loupe
//
//  Locale is famously identifying: fewer than a thousand combinations
//  of language + region + calendar + measurement system are common, and
//  once you add preferred languages the count collapses further.
//

import Foundation

struct LocaleProvider: SignalProvider {
    let category: SignalCategory = .locale

    func collect() async -> [FingerprintSignal] {
        let locale = Locale.current
        let tz = TimeZone.current
        let calendar = Calendar.current
        var signals: [FingerprintSignal] = []

        signals.append(
            .make(
                "identifier",
                category: category,
                name: String(localized: "Locale.identifier", comment: "Signal card name in the Locale & Region category — Apple's Locale.identifier property."),
                value: locale.identifier,
                rationale:
                    String(localized: "Locale string (e.g., `en_US@calendar=gregorian`) combining language, region, and calendar.", comment: "Signal card rationale beneath the Locale.identifier value.")))
        signals.append(
            .make(
                "firstDayOfWeek",
                category: category,
                name: String(localized: "First day of week", comment: "Signal card name in the Locale & Region category — Locale.firstDayOfWeek."),
                value: locale.firstDayOfWeek.rawValue,
                rationale: String(localized: "Your preferred first day of the week. May differ from your region's default.", comment: "Signal card rationale beneath the First day of week value.")))
        signals.append(
            .make(
                "hourCycle",
                category: category,
                name: String(localized: "Hour cycle", comment: "Signal card name in the Locale & Region category — Locale.hourCycle (12h or 24h preference)."),
                value: locale.hourCycle.rawValue,
                rationale: String(localized: "Your preferred time format: 12-hour or 24-hour.", comment: "Signal card rationale beneath the Hour cycle value.")))
        let prefLanguages = Locale.preferredLanguages
        signals.append(
            .make(
                "preferredLanguages",
                category: category,
                name: String(localized: "Preferred languages", comment: "Signal card name in the Locale & Region category — Locale.preferredLanguages (ordered language preference list)."),
                value: prefLanguages.joined(separator: ", "),
                rationale: String(localized: "Ordered list of preferred languages.", comment: "Signal card rationale beneath the Preferred languages value."),
                displayHint: .tags,
                entries: prefLanguages.map { SignalEntry(label: $0, value: "") }))
        signals.append(
            .make(
                "tz.identifier",
                category: category,
                name: String(localized: "Time zone identifier", comment: "Signal card name in the Locale & Region category — TimeZone.identifier (e.g., 'Europe/Berlin')."),
                value: tz.identifier,
                rationale: String(localized: "Time zone identifier (e.g., `Europe/Berlin`).", comment: "Signal card rationale beneath the Time zone identifier value.")))
        signals.append(
            .make(
                "calendar",
                category: category,
                name: String(localized: "Calendar", comment: "Signal card name in the Locale & Region category — Calendar.identifier (preferred calendar system)."),
                value: String(describing: calendar.identifier),
                rationale: String(localized: "Preferred calendar system (e.g., Gregorian, Islamic, Buddhist).", comment: "Signal card rationale beneath the Calendar value.")))

        let keyboardLanguages = PlatformTextInput.keyboardLanguageCodes()
        if !keyboardLanguages.isEmpty {
            signals.append(
                .make(
                    "keyboards",
                    category: category,
                    name: String(localized: "Keyboard languages", comment: "Signal card name in the Locale & Region category — enabled keyboard languages in order."),
                    value: "\(keyboardLanguages.joined(separator: ", "))",
                    rationale: String(localized: "Enabled keyboard languages in order.", comment: "Signal card rationale beneath the Keyboard languages value."),
                    displayHint: .tags,
                    entries: keyboardLanguages.map { SignalEntry(label: $0, value: "") }))
        }
        return signals
    }
}
