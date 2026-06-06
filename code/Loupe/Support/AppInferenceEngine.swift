//
//  AppInferenceEngine.swift
//  Loupe
//
//  Maps detected installed apps to behavioral inferences. Each
//  category fires only when enough matching apps are present,
//  producing NarrativeItems that the summary sheet can display.
//

import Foundation

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
            apps: [
                "Signal", "ProtonMail", "ProtonVPN", "DuckDuckGo",
                "1Password", "LastPass", "Bitwarden",
                "Shadowrocket", "Surge",
            ],
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
            apps: ["Coinbase", "PayPal", "Venmo", "Cash App", "Alipay"],
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
                "Weibo", "Douyin", "Xiaohongshu",
            ],
            threshold: 3
        ),
        Category(
            id: "inference.china",
            symbol: "location.fill",
            headline: String(localized: "You may live in China.", comment: "Behavioral inference shown as a card on the fingerprint summary sheet — derived from installed apps. Topic: chinese."),
            apps: ["WeChat", "QQ", "Weibo", "Alipay", "Taobao", "Douyin", "Xiaohongshu", "Netease Music"],
            threshold: 2
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
        categories.compactMap { category in
            let matched = category.apps.filter { detectedApps.contains($0) }
            guard matched.count >= category.threshold else { return nil }
            return NarrativeItem(
                id: category.id,
                symbol: category.symbol,
                headline: category.headline,
                basis: String(localized: "Inferred from \(ListFormatter.localizedString(byJoining: matched)) being installed.", comment: "Caption beneath the inference card on the fingerprint summary sheet. %@ is an Oxford-comma-joined list of app names.")
            )
        }
    }
}
