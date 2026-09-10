//
//  AppInferenceEngine.swift
//  Loupe
//
//  Maps detected installed apps to behavioral inferences. Each
//  category fires only when enough matching apps are present,
//  producing NarrativeItems that the summary sheet can display.
//

import Foundation

@MainActor
enum AppInferenceEngine {

    struct Category {
        let id: String
        let symbol: String
        let headline: String
        let apps: [String]
        let threshold: Int
    }

    private static let categories: [Category] = [
        Category(
            id: "inference.privacy",
            symbol: "lock.shield",
            headline: String(localized: "You seem to care about your privacy.", comment: "Behavioral inference shown as a card on the fingerprint summary sheet — derived from installed apps. Topic: privacy."),
            apps: ["Signal", "ProtonMail", "ProtonVPN", "DuckDuckGo", "1Password", "LastPass"],
            threshold: 2
        ),
        Category(
            id: "inference.dating",
            symbol: "heart.circle",
            headline: String(localized: "You may be actively dating.", comment: "Behavioral inference shown as a card on the fingerprint summary sheet — derived from installed apps. Topic: dating."),
            apps: ["Tinder", "Bumble", "Hinge", "Grindr"],
            threshold: 1
        ),
        Category(
            id: "inference.gaming",
            symbol: "gamecontroller",
            headline: String(localized: "You may be a gamer.", comment: "Behavioral inference shown as a card on the fingerprint summary sheet — derived from installed apps. Topic: gaming."),
            apps: ["Steam", "Twitch", "Discord"],
            threshold: 2
        ),
        Category(
            id: "inference.developer",
            symbol: "chevron.left.forwardslash.chevron.right",
            headline: String(localized: "You may be a developer or work in tech.", comment: "Behavioral inference shown as a card on the fingerprint summary sheet — derived from installed apps. Topic: developer / tech worker."),
            apps: ["GitHub", "Slack"],
            threshold: 2
        ),
        Category(
            id: "inference.finance",
            symbol: "banknote",
            headline: String(localized: "You may be interested in finance or investing.", comment: "Behavioral inference shown as a card on the fingerprint summary sheet — derived from installed apps. Topic: finance / investing."),
            apps: ["Coinbase", "PayPal", "Venmo", "Cash App"],
            threshold: 2
        ),
        Category(
            id: "inference.learner",
            symbol: "book",
            headline: String(localized: "You may be into self-improvement.", comment: "Behavioral inference shown as a card on the fingerprint summary sheet — derived from installed apps. Topic: learning / self-improvement."),
            apps: ["Duolingo"],
            threshold: 1
        ),
        Category(
            id: "inference.tesla",
            symbol: "car",
            headline: String(localized: "You likely own a Tesla.", comment: "Behavioral inference shown as a card on the fingerprint summary sheet — derived from installed apps. Topic: Tesla owner."),
            apps: ["Tesla"],
            threshold: 1
        ),
        Category(
            id: "inference.social",
            symbol: "person.3",
            headline: String(localized: "You may be a heavy social media user.", comment: "Behavioral inference shown as a card on the fingerprint summary sheet — derived from installed apps. Topic: social media usage."),
            apps: [
                "Facebook", "Instagram", "TikTok", "Snapchat", "X",
                "Threads", "Reddit", "Pinterest", "LinkedIn", "YouTube",
            ],
            threshold: 3
        ),
    ]

    /// Probes the installed-apps list via `canOpenURL` and maps the result
    /// to inference cards. In screenshot mode it returns the fixed mock
    /// inferences instead. Shared by the summary sheet and onboarding.
    @MainActor
    static func detectedInferences() -> [NarrativeItem] {
        if ScreenshotMode.isActive { return MockData.appInferences }
        var detected = Set<String>()
        for probe in InstalledAppsProvider.probes {
            guard let url = URL(string: "\(probe.scheme)://") else { continue }
            if PlatformApplication.canOpenURL(url) {
                detected.insert(probe.name)
            }
        }
        return infer(from: detected)
    }

    static func infer(from detectedApps: Set<String>) -> [NarrativeItem] {
        var covered = Set<String>()
        var items = categories.compactMap { category -> NarrativeItem? in
            let matched = category.apps.filter { detectedApps.contains($0) }
            guard matched.count >= category.threshold else { return nil }
            covered.formUnion(matched)
            return NarrativeItem(
                id: category.id,
                symbol: category.symbol,
                headline: category.headline,
                basis: String(localized: "Inferred from \(ListFormatter.localizedString(byJoining: matched)) being installed.", comment: "Caption beneath the inference card on the fingerprint summary sheet. %@ is an Oxford-comma-joined list of app names.")
            )
        }
        if let remaining = remainingItem(from: detectedApps, covered: covered) {
            items.append(remaining)
        }
        return items
    }

    /// Builds a card listing detected apps that didn't contribute to any
    /// inference that fired, so the user still sees the rest of what was
    /// probed. Apps stay in the probe-list order for a stable readout.
    private static func remainingItem(from detectedApps: Set<String>, covered: Set<String>) -> NarrativeItem? {
        let remaining = InstalledAppsProvider.probes
            .map(\.name)
            .filter { detectedApps.contains($0) && !covered.contains($0) }
        guard !remaining.isEmpty else { return nil }
        return NarrativeItem(
            id: "inference.other",
            symbol: "square.grid.2x2",
            headline: String(localized: "You have a few other apps installed, too.", comment: "Headline for the card listing detected apps that didn't fit any behavioral inference. Shown on the installed-apps onboarding page and the fingerprint summary sheet."),
            basis: String(localized: "We also spotted \(ListFormatter.localizedString(byJoining: remaining)). Each one isn't telling on its own, but it still adds to your fingerprint.", comment: "Caption beneath the remaining-apps card. %@ is an Oxford-comma-joined list of app names that didn't fit any inference.")
        )
    }
}
