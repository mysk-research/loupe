//
//  FingerprintNarrative.swift
//  Loupe
//
//  Translates passive iOS readings into one-line, plain-English claims
//  ("You're from Canada", "You speak English, German, and French") for
//  the simplified summary sheet. Each builder returns nil when the
//  reading isn't meaningful, so cards self-suppress.
//
//  No permission prompts; no network. Cards read directly from
//  Foundation, platform shims, and AVFoundation so they stay independent
//  of the per-signal provider architecture.
//

import AVFoundation
import Foundation

nonisolated struct NarrativeItem: Identifiable, Hashable {
    let id: String
    let symbol: String
    let headline: String
    let basis: String
}

@MainActor
enum FingerprintNarrative {
    // MARK: - Public

    static func items() -> [NarrativeItem] {
        if ScreenshotMode.isActive { return MockData.narrativeItems }
        return [
            country(),
            languages(),
            travel(),
            birthday(),
            headphoneOwner(),
            regionMismatch(),
            readingVision(),
            pasteboardActivity(),
            lockdownMode(),
        ].compactMap { $0 }
    }

    static func bootDate() -> Date? {
        if ScreenshotMode.isActive { return MockData.bootDate }
        guard let boot = SysctlHelper.timeval("kern.boottime") else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(boot.seconds))
    }

    static func uptimeItem(at now: Date) -> NarrativeItem? {
        guard let boot = bootDate() else { return nil }
        return NarrativeItem(
            id: "uptime",
            symbol: "clock.arrow.circlepath",
            headline:
                String(localized: "This \(PlatformDevice.localizedModel) has been running for \(uptimeString(from: boot, to: now)).", comment: "Plain-English claim about system uptime shown as a card on the fingerprint summary sheet. First %@ is the device model name (e.g., iPhone); second %@ is a formatted duration (e.g., '3 days, 4 hours, 12 minutes')."),
            basis: String(localized: "Read from the system's boot time, which is visible to any app.", comment: "Caption beneath the uptime narrative card on the fingerprint summary sheet — explains where the claim came from.")
        )
    }

    static func uptimeString(from boot: Date, to now: Date) -> String {
        let interval = max(0, now.timeIntervalSince(boot))
        return uptimeFormatter.string(from: interval) ?? String(localized: "\(Int(interval)) seconds", comment: "Fallback uptime duration when the system formatter is unavailable. %lld is a whole number of seconds.")
    }

    private static let uptimeFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.day, .hour, .minute, .second]
        f.unitsStyle = .full
        f.zeroFormattingBehavior = .dropLeading
        f.maximumUnitCount = 4
        return f
    }()

    static func fingerprintChip() -> String {
        if ScreenshotMode.isActive { return MockData.fingerprintChip }
        var parts: [String] = []

        let marketingName = PlatformDevice.marketingName
        parts.append(marketingName)
        
        if let total = volumeTotalCapacityGB() {
            parts.append("\(total) GB")
        }
        if let created = volumeCreationDate() {
            parts.append(created.formatted(.iso8601.year().month().day()))
        }

        let os = ProcessInfo.processInfo.operatingSystemVersion
        parts.append("\(PlatformDevice.systemName) \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)")

        if let region = Locale.current.region?.identifier {
            parts.append(region)
        }
        if let currency = Locale.current.currency?.identifier {
            parts.append(currency)
        }
        let langs = PlatformTextInput.keyboardLanguageCodes()
        if !langs.isEmpty {
            parts.append(langs.joined(separator: ","))
        }
        let firstDay = shortWeekday(Locale.current.firstDayOfWeek)
        let clock = is24Hour(Locale.current.hourCycle) ? "24h" : "12h"
        parts.append("\(firstDay)/\(clock)")

        parts.append(TimeZone.current.identifier)

        let pb = PlatformPasteboard.changeCount
        if pb > 0 {
            parts.append("pb:\(pb)")
        }
        if let boot = SysctlHelper.timeval("kern.boottime") {
            parts.append("boot:\(boot.seconds)")
        }

        return parts.joined(separator: " · ")
    }

    private static func volumeTotalCapacityGB() -> Int? {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        guard
            let values = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey]),
            let bytes = values.volumeTotalCapacity
        else { return nil }
        let gb = Double(bytes) / 1_000_000_000
        let tiers = [64, 128, 256, 512, 1024, 2048]
        return tiers.min(by: { abs(Double($0) - gb) < abs(Double($1) - gb) })
    }

    private static func shortWeekday(_ day: Locale.Weekday) -> String {
        switch day {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        @unknown default: return "?"
        }
    }

    // MARK: - Cards

    private static func country() -> NarrativeItem? {
        guard
            let region = Locale.current.region?.identifier,
            let name = Locale.current.localizedString(forRegionCode: region)
        else { return nil }
        return NarrativeItem(
            id: "country",
            symbol: "globe",
            headline: String(localized: "Your region is set to \(name).", comment: "Plain-English claim about region shown as a card on the fingerprint summary sheet. %@ is the localized country/region name (e.g., 'Canada')."),
            basis: String(localized: "Read from your \(PlatformDevice.localizedModel)'s region setting. A VPN does not change this.", comment: "Caption beneath the region narrative card on the fingerprint summary sheet — explains where the claim came from. %@ is the device model name (e.g., iPhone, iPad).")
        )
    }

    private static func languages() -> NarrativeItem? {
        let codes = PlatformTextInput.keyboardLanguageCodes()
        guard codes.count >= 2 else { return nil }
        let names = codes.compactMap { Locale.current.localizedString(forLanguageCode: $0) }
        guard names.count >= 2 else { return nil }
        return NarrativeItem(
            id: "languages",
            symbol: "character.bubble",
            headline: String(localized: "Your keyboards suggest you use \(ListFormatter.localizedString(byJoining: names)).", comment: "Plain-English claim about spoken languages shown as a card on the fingerprint summary sheet. %@ is an Oxford-comma-joined list of language names."),
            basis: String(localized: "Read from the enabled keyboard languages.", comment: "Caption beneath the languages narrative card on the fingerprint summary sheet — explains where the claim came from.")
        )
    }

    private static func travel() -> NarrativeItem? {
        guard
            let homeRegion = Locale.current.region?.identifier,
            let tzRegion = country(forTimeZone: TimeZone.current),
            tzRegion != homeRegion,
            let tzCountryName = Locale.current.localizedString(forRegionCode: tzRegion)
        else { return nil }
        return NarrativeItem(
            id: "travel",
            symbol: "airplane",
            headline: String(localized: "Your time zone hints that you might be visiting or traveling in \(tzCountryName).", comment: "Plain-English claim about travel shown as a card on the fingerprint summary sheet. %@ is the localized country/region name implied by the device's time zone."),
            basis: String(localized: "Inferred from a time zone (\(TimeZone.current.identifier)) that doesn't match your \(PlatformDevice.localizedModel)'s region setting.", comment: "Caption beneath the travel narrative card on the fingerprint summary sheet — explains where the claim came from. First %@ is the time-zone identifier (e.g., 'Europe/Berlin'); second %@ is the device model name (e.g., iPhone).")
        )
    }

    private static func birthday() -> NarrativeItem? {
        guard let created = volumeCreationDate() else { return nil }
        let formatted = created.formatted(date: .long, time: .standard
        )
        return NarrativeItem(
            id: "birthday",
            symbol: "gift",
            headline: String(localized: "This \(PlatformDevice.localizedModel) was set up or last erased on \(formatted).", comment: "Plain-English claim about the device's 'birthday' shown as a card on the fingerprint summary sheet. First %@ is the device model name (e.g., iPhone); second %@ is a localized long date+time string."),
            basis: String(localized: "Read from the storage volume's creation date. How many other \(PlatformDevice.marketingName) devices do you think were set up at that exact second?", comment: "Caption beneath the birthday narrative card on the fingerprint summary sheet — explains where the claim came from. %@ is the marketing name (e.g., 'iPhone 16 Pro').")
        )
    }

    private static func headphoneOwner() -> NarrativeItem? {
        #if os(iOS)
        let route = AVAudioSession.sharedInstance().currentRoute
        let ports = route.outputs + route.inputs

        // Built-in I/O ports never carry an owner name, so skip past them
        // to find a paired accessory further down the route.
        let builtInPortTypes: Set<AVAudioSession.Port> = [
            .builtInSpeaker, .builtInReceiver, .builtInMic,
        ]

        var fallback: NarrativeItem?

        for port in ports where !builtInPortTypes.contains(port.portType) {
            if let owner = ownerName(in: port.portName) {
                return NarrativeItem(
                    id: "owner",
                    symbol: "airpods.pro",
                    headline:
                        String(localized: "Your audio accessory is named \"\(port.portName)\"… so your name might be \(owner)?", comment: "Plain-English claim about headphone owner shown as a card on the fingerprint summary sheet. First %@ is the accessory's name (e.g., \"Talal's AirPods\"); second %@ is the personal name extracted from it."),
                    basis: String(localized: "Read from the connected audio device's name.", comment: "Caption beneath the headphone-owner narrative card on the fingerprint summary sheet — explains where the claim came from.")
                )
            } else if fallback == nil {
                fallback = NarrativeItem(
                    id: "owner",
                    symbol: "airpods.pro",
                    headline:
                        String(localized: "Your audio accessory is named \"\(port.portName)\"", comment: "Plain-English claim about the connected audio accessory shown as a card on the fingerprint summary sheet when no personal name could be extracted. %@ is the accessory's name."),
                    basis: String(localized: "Read from the connected audio device's name.", comment: "Caption beneath the audio-accessory narrative card on the fingerprint summary sheet — explains where the claim came from.")
                )
            }
        }
        return fallback
        #else
        return nil
        #endif
    }

    private static func regionMismatch() -> NarrativeItem? {
        guard let region = Locale.current.region else { return nil }
        let countryName =
            Locale.current.localizedString(forRegionCode: region.identifier) ?? region.identifier

        let langCode = Locale.current.language.languageCode?.identifier ?? "en"
        let baseline = Locale(identifier: "\(langCode)_\(region.identifier)")
        let current = Locale.current

        var clauses: [String] = []

        if current.calendar.identifier != baseline.calendar.identifier {
            clauses.append(
                String(localized: "use the \(calendarName(current.calendar.identifier)) calendar instead of \(calendarName(baseline.calendar.identifier))", comment: "Region-mismatch sub-clause about calendar systems on the fingerprint summary sheet. First %@ is the user's chosen calendar name; second %@ is the baseline calendar for their region. Will be joined with other clauses by Oxford comma.")
            )
        }

        let curIs24 = is24Hour(current.hourCycle)
        let baseIs24 = is24Hour(baseline.hourCycle)
        if curIs24 != baseIs24 {
            let cur = curIs24 ? String(localized: "24-hour clock", comment: "Clock format label — the user's current setting in the region-mismatch narrative.") : String(localized: "12-hour clock", comment: "Clock format label — the user's current setting in the region-mismatch narrative.")
            let base = baseIs24 ? String(localized: "24-hour clock", comment: "Clock format baseline — the region's default clock format in the region-mismatch narrative.") : String(localized: "12-hour clock", comment: "Clock format baseline — the region's default clock format in the region-mismatch narrative.")
            clauses.append(String(localized: "prefer \(cur) instead of \(base)", comment: "Region-mismatch sub-clause about clock format on the fingerprint summary sheet. First %@ is the user's chosen clock format; second %@ is the regional baseline. Will be joined with other clauses by Oxford comma."))
        }

        if current.firstDayOfWeek != baseline.firstDayOfWeek {
            clauses.append(
                String(localized: "your week starts \(weekdayName(current.firstDayOfWeek)) instead of \(weekdayName(baseline.firstDayOfWeek))", comment: "Region-mismatch sub-clause about first day of week on the fingerprint summary sheet. First %@ is the user's chosen weekday name; second %@ is the regional default. Will be joined with other clauses by Oxford comma.")
            )
        }

        if current.measurementSystem != baseline.measurementSystem {
            clauses.append(
                String(localized: "prefer \(measurementName(current.measurementSystem)) units instead of \(measurementName(baseline.measurementSystem))", comment: "Region-mismatch sub-clause about measurement system on the fingerprint summary sheet. First %@ is the user's chosen measurement system (e.g., 'metric'); second %@ is the regional baseline. Will be joined with other clauses by Oxford comma.")
            )
        }

        let curTemp = preferredTemperature(in: current)
        let baseTemp = preferredTemperature(in: baseline)
        if curTemp != baseTemp {
            clauses.append(String(localized: "prefer \(curTemp) over \(baseTemp)", comment: "Region-mismatch sub-clause about preferred temperature unit on the fingerprint summary sheet. First %@ is the user's chosen temperature unit name; second %@ is the regional baseline. Will be joined with other clauses by Oxford comma."))
        }

        if let curCur = current.currency?.identifier,
           let baseCur = baseline.currency?.identifier,
           curCur != baseCur {
            let cName = current.localizedString(forCurrencyCode: curCur) ?? curCur
            let bName = current.localizedString(forCurrencyCode: baseCur) ?? baseCur
            clauses.append(String(localized: "price things in \(cName) instead of \(bName)", comment: "Region-mismatch sub-clause about currency on the fingerprint summary sheet. First %@ is the user's chosen currency name; second %@ is the regional baseline. Will be joined with other clauses by Oxford comma."))
        }

        var dc = DateComponents()
        dc.year = 2026
        dc.month = 5
        dc.day = 27
        if let sample = Calendar(identifier: .gregorian).date(from: dc) {
            let curDate = sample.formatted(.dateTime.year().month().day().locale(current))
            let baseDate = sample.formatted(.dateTime.year().month().day().locale(baseline))
            if curDate != baseDate {
                clauses.append(String(localized: "write dates as \"\(curDate)\" instead of \"\(baseDate)\"", comment: "Region-mismatch sub-clause about date formatting on the fingerprint summary sheet. First %@ is the user's locale-formatted sample date; second %@ is the regional baseline. Will be joined with other clauses by Oxford comma."))
            }
        }

        let curNum = (1234.5).formatted(.number.locale(current))
        let baseNum = (1234.5).formatted(.number.locale(baseline))
        if curNum != baseNum {
            clauses.append(String(localized: "write numbers as \(curNum) instead of \(baseNum)", comment: "Region-mismatch sub-clause about number formatting on the fingerprint summary sheet. First %@ is the user's locale-formatted sample number; second %@ is the regional baseline. Will be joined with other clauses by Oxford comma."))
        }

        guard !clauses.isEmpty else { return nil }

        return NarrativeItem(
            id: "regionMismatch",
            symbol: "slider.horizontal.3",
            headline: String(localized: "Your region is \(countryName), but you \(ListFormatter.localizedString(byJoining: clauses)).", comment: "Plain-English claim about region-vs-settings mismatch shown as a card on the fingerprint summary sheet. First %@ is the localized country/region name; second %@ is an Oxford-comma-joined list of mismatch clauses (each describing one setting the user has customized away from the regional default)."),
            basis: String(localized: "Comparing your region's defaults with the settings you've customized.", comment: "Caption beneath the region-mismatch narrative card on the fingerprint summary sheet — explains where the claim came from.")
        )
    }

    private static func readingVision() -> NarrativeItem? {
        var labels: [String] = []
        if PlatformApplication.preferredContentSizeCategoryIsLarge {
            labels.append(PlatformApplication.preferredContentSizeCategoryIsAccessibility ? String(localized: "very large text", comment: "Accessibility-feature label used inside the reading/vision narrative card on the fingerprint summary sheet — appears in an Oxford-comma list.") : String(localized: "larger text", comment: "Accessibility-feature label used inside the reading/vision narrative card on the fingerprint summary sheet — appears in an Oxford-comma list."))
        }
        if PlatformAccessibility.isBoldTextEnabled { labels.append(String(localized: "bold text", comment: "Accessibility-feature label used inside the reading/vision narrative card on the fingerprint summary sheet — appears in an Oxford-comma list.")) }
        if PlatformAccessibility.isDarkerSystemColorsEnabled { labels.append(String(localized: "increased contrast", comment: "Accessibility-feature label used inside the reading/vision narrative card on the fingerprint summary sheet — appears in an Oxford-comma list.")) }
        if PlatformAccessibility.shouldDifferentiateWithoutColor {
            labels.append(String(localized: "shapes instead of colour", comment: "Accessibility-feature label used inside the reading/vision narrative card on the fingerprint summary sheet — appears in an Oxford-comma list."))
        }
        if PlatformAccessibility.buttonShapesEnabled { labels.append(String(localized: "visible button shapes", comment: "Accessibility-feature label used inside the reading/vision narrative card on the fingerprint summary sheet — appears in an Oxford-comma list.")) }
        if PlatformAccessibility.isOnOffSwitchLabelsEnabled { labels.append(String(localized: "on/off switch labels", comment: "Accessibility-feature label used inside the reading/vision narrative card on the fingerprint summary sheet — appears in an Oxford-comma list.")) }
        if PlatformAccessibility.isReduceTransparencyEnabled { labels.append(String(localized: "reduced transparency", comment: "Accessibility-feature label used inside the reading/vision narrative card on the fingerprint summary sheet — appears in an Oxford-comma list.")) }

        guard !labels.isEmpty else { return nil }

        return NarrativeItem(
            id: "readingVision",
            symbol: "textformat.size",
            headline: String(localized: "You have accessibility settings turned on: \(ListFormatter.localizedString(byJoining: labels)).", comment: "Plain-English claim about accessibility settings shown as a card on the fingerprint summary sheet. %@ is an Oxford-comma-joined list of accessibility-feature names."),
            basis: String(localized: "Read from accessibility flags any app can check.", comment: "Caption beneath the reading/vision accessibility narrative card on the fingerprint summary sheet — explains where the claim came from.")
        )
    }

    private static func lockdownMode() -> NarrativeItem? {
        let enabled = UserDefaults.standard.bool(forKey: "LDMGlobalEnabled")
        guard enabled else { return nil }
        return NarrativeItem(
            id: "lockdownMode",
            symbol: "lock.shield",
            headline: String(localized: "Lockdown Mode is turned on for this \(PlatformDevice.localizedModel).", comment: "Plain-English claim about Lockdown Mode shown as a card on the fingerprint summary sheet. %@ is the device model name (e.g., iPhone, iPad)."),
            basis: String(localized: "Lockdown Mode is uncommon and has to be turned on manually.", comment: "Caption beneath the Lockdown Mode narrative card on the fingerprint summary sheet — explains why the claim is identifying.")
        )
    }

    private static func pasteboardActivity() -> NarrativeItem? {
        let count = PlatformPasteboard.changeCount
        guard count > 0 else { return nil }
        return NarrativeItem(
            id: "pasteboard",
            symbol: "doc.on.clipboard",
            headline:
                String(localized: .youveCopiedOrCutSomethingTimesSinceThisWasSetUp(count: count, device: PlatformDevice.localizedModel)),
            basis:
                String(localized: "Read from the clipboard's change counter, a shared number any app can read.", comment: "Caption beneath the pasteboard narrative card on the fingerprint summary sheet — explains where the claim came from.")
        )
    }

    // MARK: - Helpers

    private static func volumeCreationDate() -> Date? {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        let values = try? url.resourceValues(forKeys: [.volumeCreationDateKey])
        return values?.volumeCreationDate
    }

    private static func country(forTimeZone tz: TimeZone) -> String? {
        TimeZoneCountries.countryCode(for: tz.identifier)
    }

    // Apple derives a freshly paired accessory's name from the owner's Apple
    // Account first name, formatted per the system language at pairing time.
    // The grammar differs by locale, so we try each known shape in priority
    // order and return the first owner name we can extract. Matching is
    // language-agnostic on purpose: an accessory may have been named under a
    // different system language than the phone is set to right now.
    private static let ownerNamePatterns: [(pattern: String, caseInsensitive: Bool)] = [
        // English possessive: "Talal's AirPods".
        (#"^([\p{Lu}][\p{L}'’‘\-]*)['’‘]s\s"#, false),
        // Turkish possessive: "Talal'ın AirPods'u" (apostrophe + vowel-harmony suffix).
        (#"^(\p{L}[\p{L}\-]*)['’](?:ın|in|un|ün|nın|nin|nun|nün)\s"#, true),
        // CJK particle: Japanese "TalalのAirPods", Chinese "Talal的AirPods".
        (#"^(\S.{0,23}?)(?:の|的)\S"#, false),
        // Romance / German / Vietnamese connector with the name at the end:
        // "AirPods de Talal" (es/fr/pt), "AirPods di Talal" (it), "AirPods d'Talal" (fr),
        // "AirPods von Talal" (de), "AirPods của Talal" (vi).
        (#"(?:\sde\s|\sdi\s|\sd['’]|\svon\s|\scủa\s)([\p{Lu}][\p{L}'’‘\-]*(?:\s[\p{Lu}][\p{L}'’‘\-]*)?)\s*$"#, false),
        // German bare genitive, gated on a known Apple audio noun: "Talals AirPods".
        (#"^([\p{Lu}][\p{L}\-]+)s\s(?=AirPods|Beats|EarPods|Powerbeats)"#, false),
        // Arabic: "AirPods الخاصة بـTalal".
        (#"الخاصة\s*بـ?\s*(\S+)\s*$"#, false),
    ]

    private static func ownerName(in portName: String) -> String? {
        for entry in ownerNamePatterns {
            if let name = firstCapture(of: entry.pattern, in: portName, caseInsensitive: entry.caseInsensitive) {
                return name
            }
        }
        return nil
    }

    private static func firstCapture(of pattern: String, in string: String, caseInsensitive: Bool) -> String? {
        let options: NSRegularExpression.Options = caseInsensitive ? [.caseInsensitive] : []
        guard
            let regex = try? NSRegularExpression(pattern: pattern, options: options),
            let match = regex.firstMatch(
                in: string,
                range: NSRange(string.startIndex..., in: string)),
            match.numberOfRanges >= 2,
            let range = Range(match.range(at: 1), in: string)
        else { return nil }
        let captured = string[range].trimmingCharacters(in: .whitespaces)
        return captured.isEmpty ? nil : captured
    }

    private static func is24Hour(_ cycle: Locale.HourCycle) -> Bool {
        switch cycle {
        case .zeroToTwentyThree, .oneToTwentyFour: return true
        case .zeroToEleven, .oneToTwelve: return false
        @unknown default: return false
        }
    }

    private static func calendarName(_ id: Calendar.Identifier) -> String {
        switch id {
        case .gregorian: return String(localized: "Gregorian", comment: "Calendar name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .buddhist: return String(localized: "Buddhist", comment: "Calendar name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .chinese: return String(localized: "Chinese", comment: "Calendar name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .coptic: return String(localized: "Coptic", comment: "Calendar name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .ethiopicAmeteMihret: return String(localized: "Ethiopic", comment: "Calendar name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .ethiopicAmeteAlem: return String(localized: "Ethiopic (Amete Alem)", comment: "Calendar name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .hebrew: return String(localized: "Hebrew", comment: "Calendar name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .indian: return String(localized: "Indian National", comment: "Calendar name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .islamic, .islamicCivil, .islamicTabular, .islamicUmmAlQura: return String(localized: "Islamic", comment: "Calendar name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .iso8601: return "ISO 8601"
        case .japanese: return String(localized: "Japanese", comment: "Calendar name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .persian: return String(localized: "Persian", comment: "Calendar name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .republicOfChina: return String(localized: "Republic of China", comment: "Calendar name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        default: return "\(id)".capitalized
        }
    }

    private static func weekdayName(_ day: Locale.Weekday) -> String {
        switch day {
        case .sunday: return String(localized: "Sunday", comment: "Weekday name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .monday: return String(localized: "Monday", comment: "Weekday name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .tuesday: return String(localized: "Tuesday", comment: "Weekday name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .wednesday: return String(localized: "Wednesday", comment: "Weekday name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .thursday: return String(localized: "Thursday", comment: "Weekday name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .friday: return String(localized: "Friday", comment: "Weekday name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .saturday: return String(localized: "Saturday", comment: "Weekday name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        @unknown default: return String(describing: day)
        }
    }

    private static func measurementName(_ ms: Locale.MeasurementSystem) -> String {
        switch ms {
        case .metric: return String(localized: "metric", comment: "Measurement-system name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .us: return String(localized: "imperial", comment: "Measurement-system name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        case .uk: return String(localized: "imperial (UK)", comment: "Measurement-system name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
        default: return String(describing: ms)
        }
    }

    private static func preferredTemperature(in locale: Locale) -> String {
        let zero = Measurement(value: 0, unit: UnitTemperature.celsius)
        let formatted = zero.formatted(
            .measurement(width: .abbreviated, usage: .weather).locale(locale))
        return formatted.contains("F") ? String(localized: "Fahrenheit", comment: "Temperature-unit name used inside the region-mismatch narrative card on the fingerprint summary sheet.") : String(localized: "Celsius", comment: "Temperature-unit name used inside the region-mismatch narrative card on the fingerprint summary sheet.")
    }

}
