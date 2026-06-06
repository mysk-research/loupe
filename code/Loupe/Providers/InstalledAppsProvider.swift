//
//  InstalledAppsProvider.swift
//  Loupe
//
//  Probes a curated list of third-party URL schemes with `canOpenURL`.
//  Every scheme you list must be declared in Info.plist under
//  LSApplicationQueriesSchemes. Apple caps that list at 50 entries.
//

import Foundation

struct InstalledAppsProvider: SignalProvider {
    let category: SignalCategory = .installedApps

    struct Probe: Sendable, Hashable {
        let name: String
        let scheme: String
    }

    static let probes: [Probe] = [
        Probe(name: "WhatsApp", scheme: "whatsapp"),
        Probe(name: "Telegram", scheme: "tg"),
        Probe(name: "Signal", scheme: "sgnl"),
        Probe(name: "Facebook", scheme: "fb"),
        Probe(name: "Messenger", scheme: "fb-messenger"),
        Probe(name: "Instagram", scheme: "instagram"),
        Probe(name: "Threads", scheme: "barcelona"),
        Probe(name: "X", scheme: "twitter"),
        Probe(name: "TikTok", scheme: "tiktok"),
        Probe(name: "Snapchat", scheme: "snapchat"),
        Probe(name: "LinkedIn", scheme: "linkedin"),
        Probe(name: "Reddit", scheme: "reddit"),
        Probe(name: "Discord", scheme: "discord"),
        Probe(name: "Slack", scheme: "slack"),
        Probe(name: "Zoom", scheme: "zoomus"),
        Probe(name: "Teams", scheme: "msteams"),
        Probe(name: "Tesla", scheme: "tesla"),
        Probe(name: "YouTube", scheme: "youtube"),
        Probe(name: "Spotify", scheme: "spotify"),
        Probe(name: "Netflix", scheme: "nflx"),
        Probe(name: "Google Maps", scheme: "comgooglemaps"),
        Probe(name: "Waze", scheme: "waze"),
        Probe(name: "Uber", scheme: "uber"),
        Probe(name: "Duolingo", scheme: "duolingo"),
        Probe(name: "Tinder", scheme: "tinder"),
        Probe(name: "Deliveroo", scheme: "deliveroo"),
        Probe(name: "Chrome", scheme: "googlechrome"),
        Probe(name: "Firefox", scheme: "firefox"),
        Probe(name: "Edge", scheme: "microsoft-edge"),
        Probe(name: "DuckDuckGo", scheme: "ddgQuickLink"),
        Probe(name: "Gmail", scheme: "googlegmail"),
        Probe(name: "Outlook", scheme: "ms-outlook"),
        Probe(name: "ProtonMail", scheme: "protonmail"),
        Probe(name: "PayPal", scheme: "paypal"),
        Probe(name: "1Password", scheme: "onepassword"),
        Probe(name: "LastPass", scheme: "lastpass"),
        Probe(name: "GitHub", scheme: "github"),
        Probe(name: "Pinterest", scheme: "pinterest"),
        Probe(name: "Amazon", scheme: "com.amazon.mobile.shopping"),
        Probe(name: "Bumble", scheme: "bumble"),
        Probe(name: "Hinge", scheme: "hinge"),
        Probe(name: "Grindr", scheme: "grindr"),
        Probe(name: "Venmo", scheme: "venmo"),
        Probe(name: "Cash App", scheme: "squarecash"),
        Probe(name: "Lyft", scheme: "lyft"),
        Probe(name: "DoorDash", scheme: "doordash"),
        Probe(name: "Twitch", scheme: "twitch"),
        Probe(name: "Steam", scheme: "steam"),
        Probe(name: "Coinbase", scheme: "coinbase"),
        Probe(name: "ProtonVPN", scheme: "protonvpn"),
        Probe(name: "WeChat", scheme: "weixin"),
        Probe(name: "QQ", scheme: "mqq"),
        Probe(name: "Weibo", scheme: "weibo"),
        Probe(name: "Alipay", scheme: "alipay"),
        Probe(name: "Taobao", scheme: "taobao"),
        Probe(name: "Douyin", scheme: "snssdk1128"),
        Probe(name: "Xiaohongshu", scheme: "xhsdiscover"),
        Probe(name: "Netease Music", scheme: "orpheus"),
        Probe(name: "Shadowrocket", scheme: "shadowrocket"),
        Probe(name: "Surge", scheme: "surge"),
        Probe(name: "Bitwarden", scheme: "bitwarden"),
    ]

    func collect() async -> [FingerprintSignal] {
        var installed: [String] = []
        var missing: [String] = []
        for probe in Self.probes {
            guard let url = URL(string: "\(probe.scheme)://") else { continue }
            if PlatformApplication.canOpenURL(url) {
                installed.append(probe.name)
            } else {
                missing.append(probe.name)
            }
        }
        let installedBody = installed.isEmpty ? "(none detected)" : installed.joined(separator: ", ")
        let missingBody = missing.isEmpty ? "(none)" : missing.joined(separator: ", ")
        return [
            .make(
                "installed",
                category: category,
                name: String(localized: "Detected apps", comment: "Signal card name in the Installed Apps Probe category — apps for which canOpenURL returned true."),
                value: "\(installed.count) of \(Self.probes.count): \(installedBody)",
                rationale:
                    String(localized: "Detected by calling `canOpenURL` against each URL scheme.", comment: "Signal card rationale beneath the Detected apps value."),
                displayHint: installed.isEmpty ? .plain : .tags,
                entries: installed.isEmpty ? nil : installed.map { SignalEntry(label: $0, value: "") }),
            .make(
                "missing",
                category: category,
                name: String(localized: "Missing apps", comment: "Signal card name in the Installed Apps Probe category — apps from the probe list that canOpenURL returned false for."),
                value: missingBody,
                rationale:
                    String(localized: "Apps from the same list where `canOpenURL` returned `false`.", comment: "Signal card rationale beneath the Missing apps value."),
                displayHint: missing.isEmpty ? .plain : .tags,
                entries: missing.isEmpty ? nil : missing.map { SignalEntry(label: $0, value: "") }),
        ]
    }
}
