//
//  MockData.swift
//  Loupe
//
//  Fixed, believable readings used only when `ScreenshotMode.isActive`
//  (the `-LoupeMockData` launch argument). They let App Store screenshots
//  show a consistent persona without depending on whatever device or
//  simulator the capture happens to run on.
//
//  Persona: an iPhone 17 Pro Max set up in Canada, with English, Arabic,
//  and Japanese keyboards. Values are intentionally specific so the
//  fingerprinting story reads clearly. User-facing names and rationales
//  reuse the same localized strings as the live providers, so they stay
//  on-voice and share existing translations; only the data values differ.
//
//  Run screenshots on an iPhone 17 Pro Max simulator so the live device
//  model strings (PlatformDevice.marketingName / .localizedModel) line up
//  with the persona. On iPad the same persona is reused, but the readings
//  that name the device type (device name, hostname, model identifier, GPU,
//  web user agent) switch to their iPad equivalents to match the simulator.
//

import Foundation

#if os(iOS)
import UIKit
#endif

@MainActor
enum MockData {

    // MARK: - Device idiom

    /// Screenshots run on both iPhone and iPad. A few readings name the device
    /// type, so they follow the idiom to match the simulator the capture runs
    /// on. Everything else in the persona stays identical across both.
    private static var isPad: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }

    /// Generic device name iOS / iPadOS report to apps ("iPhone" or "iPad").
    private static var deviceNoun: String { isPad ? "iPad" : "iPhone" }

    /// Apple's internal hardware identifier for the capture device.
    private static var modelIdentifier: String {
        isPad ? "iPad17,2 (board J717AP)" : "iPhone18,4 (board D94AP)"
    }

    /// GPU name as Metal reports it.
    private static var gpuName: String {
        isPad ? "Apple M5 GPU" : "Apple A19 Pro GPU"
    }

    /// Default WebView user agent for the device class.
    private static var webUserAgent: String {
        isPad
            ? "Mozilla/5.0 (iPad; CPU OS 26_4 like Mac OS X) AppleWebKit/620.1.16 (KHTML, like Gecko) Mobile/15E148"
            : "Mozilla/5.0 (iPhone; CPU iPhone OS 26_4 like Mac OS X) AppleWebKit/620.1.16 (KHTML, like Gecko) Mobile/15E148"
    }

    // MARK: - Persona constants

    /// Apps the persona "has installed". Drives both the Installed Apps
    /// category and the behavioral inference cards so they stay consistent.
    static let detectedApps: Set<String> = [
        "WhatsApp", "Telegram", "Signal", "Instagram", "X", "Threads",
        "Reddit", "Discord", "Slack", "GitHub", "1Password", "ProtonMail",
        "ProtonVPN", "Spotify", "YouTube", "Uber", "Duolingo", "Tesla",
    ]

    // MARK: - Narrative (highlights + onboarding page 3)

    static var narrativeItems: [NarrativeItem] {
        [
            NarrativeItem(
                id: "country",
                symbol: "globe",
                headline: String(localized: "Your region is set to \("Canada")."),
                basis: String(localized: "Read from your \(PlatformDevice.localizedModel)'s region setting. A VPN does not change this.")
            ),
            NarrativeItem(
                id: "languages",
                symbol: "character.bubble",
                headline: String(localized: "Your keyboards suggest you use \("English, Arabic, and Japanese")."),
                basis: String(localized: "Read from the enabled keyboard languages.")
            ),
            NarrativeItem(
                id: "birthday",
                symbol: "gift",
                headline: String(localized: "This \(PlatformDevice.localizedModel) was set up or last erased on \("May 14, 2026 at 3:58:10 PM")."),
                basis: String(localized: "Read from the storage volume's creation date. How many other \(PlatformDevice.marketingName) devices do you think were set up at that exact second?")
            ),
            NarrativeItem(
                id: "pasteboard",
                symbol: "doc.on.clipboard",
                headline: String(localized: .youveCopiedOrCutSomethingTimesSinceThisWasSetUp(count: 3256, device: PlatformDevice.localizedModel)),
                basis: String(localized: "Read from the clipboard's change counter, a shared number any app can read.")
            ),
        ]
    }

    /// Inference cards derived from `detectedApps` via the real engine, so
    /// the wording and thresholds match production exactly.
    static var appInferences: [NarrativeItem] {
        AppInferenceEngine.infer(from: detectedApps)
    }

    /// A fixed boot time a little over seven days ago. Evaluated relative to
    /// launch so the animated uptime card reads a believable duration.
    static var bootDate: Date {
        Date().addingTimeInterval(-(7 * 86_400 + 10 * 3_600 + 8 * 60 + 17))
    }

    static var fingerprintChip: String {
        [
            PlatformDevice.marketingName,
            "512 GB",
            "2026-05-14",
            "iOS 26.4",
            "CA",
            "CAD",
            "en-CA,ar,ja-JP",
            "Sun/12h",
            "America/Toronto",
            "pb:3256",
            "boot:1747251490",
        ].joined(separator: " · ")
    }

    // MARK: - Category signals

    static var signals: [SignalCategory: [FingerprintSignal]] {
        var result: [SignalCategory: [FingerprintSignal]] = [:]
        result[.deviceIdentity] = deviceIdentity
        result[.appleAccount] = appleAccount
        result[.systemInfo] = systemInfo
        result[.display] = display
        result[.locale] = locale
        result[.accessibility] = accessibility
        result[.deviceMotion] = deviceMotion
        result[.battery] = battery
        result[.storage] = storage
        result[.network] = network
        result[.fonts] = fonts
        result[.voices] = voices
        result[.appInfo] = appInfo
        result[.pasteboard] = pasteboard
        result[.audioRoute] = audioRoute
        result[.metal] = metal
        result[.telephony] = telephony
        result[.installedApps] = installedApps
        result[.webViewFingerprint] = webViewFingerprint
        result[.previousInstalls] = previousInstalls
        result[.motion] = motion
        result[.location] = location
        result[.camera] = camera
        result[.bluetooth] = bluetooth
        result[.localNetwork] = localNetwork
        result[.contacts] = contacts
        result[.photos] = photos
        result[.calendar] = calendar
        result[.reminders] = reminders
        result[.musicLibrary] = musicLibrary
        return result
    }

    // MARK: - Passive categories

    private static var deviceIdentity: [FingerprintSignal] {
        [
            .make("idfv", category: .deviceIdentity,
                  name: String(localized: "identifierForVendor"),
                  value: "9F2C7A1B-4D3E-4C5F-8A6B-1E2D3C4B5A6F",
                  rationale: String(localized: "Stays the same across every app from the same developer, until you uninstall all of them.")),
            .make("name", category: .deviceIdentity,
                  name: String(localized: "Device name"),
                  value: deviceNoun,
                  rationale: String(localized: "Usually a generic product name on iOS and iPadOS 16+. A handful of Apple-approved apps (through entitlements) can still see the name you set.")),
            .make("kern.hostname", category: .deviceIdentity,
                  name: String(localized: "kern.hostname"),
                  value: deviceNoun,
                  rationale: String(localized: "The DNS hostname. On some setups, it matches the name you've given your \(PlatformDevice.localizedModel).")),
            .make("systemVersion", category: .deviceIdentity,
                  name: String(localized: "systemVersion"),
                  value: "26.4",
                  rationale: String(localized: "Your specific \(PlatformDevice.systemName) version.")),
            .make("hw.machine", category: .deviceIdentity,
                  name: String(localized: "Model identifier"),
                  value: modelIdentifier,
                  rationale: String(localized: "Apple's internal hardware identifier (e.g., iPhone16,1 or MacBookPro18,2).")),
            .make("hw.cputype", category: .deviceIdentity,
                  name: String(localized: "hw.cputype"),
                  value: "16777228 / sub 2",
                  rationale: String(localized: "CPU architecture identifiers from the kernel.")),
        ]
    }

    private static var appleAccount: [FingerprintSignal] {
        [
            .make("ubiquityToken.hash", category: .appleAccount,
                  name: String(localized: "iCloud token hash"),
                  value: "4f3b9a1c8e7d6052a3b4c5d6e7f80912a3b4c5d6e7f8091223344556677889900",
                  rationale: String(localized: "A hash of the iCloud account token. The token isn't shared between different apps, though for the same app it remains consistent across app installs.")),
            .make("storefront.country", category: .appleAccount,
                  name: String(localized: "App Store country"),
                  value: "CAN",
                  rationale: String(localized: "ISO country code from your App Store account. Pins the account to a country regardless of where the \(PlatformDevice.localizedModel) is right now.")),
        ]
    }

    private static var systemInfo: [FingerprintSignal] {
        [
            .make("processorCount", category: .systemInfo,
                  name: String(localized: "Processor count"),
                  value: "6",
                  rationale: String(localized: "Number of CPU cores visible to apps. Can fluctuate with thermal throttling.")),
            .make("physicalMemory", category: .systemInfo,
                  name: String(localized: "Physical memory"),
                  value: "12 GB",
                  rationale: String(localized: "Total RAM on your \(PlatformDevice.localizedModel).")),
            .make("operatingSystem", category: .systemInfo,
                  name: String(localized: "OS version string"),
                  value: "Version 26.4 (Build 23E224)",
                  rationale: String(localized: "The full \(PlatformDevice.systemName) version string the system reports.")),
            .make("kern.version", category: .systemInfo,
                  name: String(localized: "kern.version"),
                  value: "Darwin Kernel Version 25.4.0: Tue Mar 17 21:42:08 PDT 2026; root:xnu-11500.101.3~4/RELEASE_ARM64_T8150",
                  rationale: String(localized: "The kernel version string, with build details and compiler timestamps.")),
            .make("kern.boottime", category: .systemInfo,
                  name: String(localized: "Boot time"),
                  value: "2026-05-24T01:21:13Z",
                  rationale: String(localized: "When your \(PlatformDevice.localizedModel) last booted. Stays the same until the next restart.")),
            .make("lockdownMode", category: .systemInfo,
                  name: String(localized: "Lockdown Mode"),
                  value: String(localized: "Not enabled", comment: "Lockdown Mode signal value when Lockdown Mode is turned off."),
                  rationale: String(localized: "Whether you have \(PlatformDevice.systemName) Lockdown Mode turned on.")),
        ]
    }

    private static var display: [FingerprintSignal] {
        [
            .make("nativeBounds", category: .display,
                  name: String(localized: "Native bounds"),
                  value: "1320x2868",
                  rationale: String(localized: "The screen's physical pixel dimensions.")),
            .make("scale", category: .display,
                  name: String(localized: "scale"),
                  value: "3.00",
                  rationale: String(localized: "Point-to-pixel ratio (the canonical @2x / @3x value).")),
            .make("nativeScale", category: .display,
                  name: String(localized: "nativeScale"),
                  value: "3.0000",
                  rationale: String(localized: "Actual downscale ratio. Differs from `scale` on Plus/Pro Max models.")),
            .make("maxFPS", category: .display,
                  name: String(localized: "Max frames per second"),
                  value: "120",
                  rationale: String(localized: "60 Hz on most devices, 120 Hz on ProMotion displays.")),
            .make("brightness", category: .display,
                  name: String(localized: "Brightness"),
                  value: "0.68",
                  rationale: String(localized: "Current screen brightness (0.0 to 1.0). Changes with your adjustments and ambient light.")),
            .make("displayGamut", category: .display,
                  name: String(localized: "displayGamut"),
                  value: "P3",
                  rationale: String(localized: "sRGB or P3. Newer displays support P3.")),
            .make("sizeClass", category: .display,
                  name: String(localized: "Size class"),
                  value: "compact × regular",
                  rationale: String(localized: "Compact vs regular in each axis. Varies by device type and orientation."),
                  displayHint: .compound,
                  entries: [
                    SignalEntry(label: String(localized: "Horizontal"), value: "compact"),
                    SignalEntry(label: String(localized: "Vertical"), value: "regular"),
                  ]),
            .make("preferredContentSizeCategory", category: .display,
                  name: String(localized: "preferredContentSizeCategory"),
                  value: "UICTContentSizeCategoryL",
                  rationale: String(localized: "Dynamic Type size: the text-size preference you've set in Settings.")),
            .make("safeAreaInsets", category: .display,
                  name: String(localized: "safeAreaInsets"),
                  value: "top=62.0 left=0.0 bottom=34.0 right=0.0",
                  rationale: String(localized: "Inset values shaped by the notch or Dynamic Island. Varies by device chassis."),
                  displayHint: .keyValue,
                  entries: [
                    SignalEntry(label: String(localized: "top", comment: "Safe-area sub-label in the Display category — top inset."), value: "62.0"),
                    SignalEntry(label: String(localized: "left", comment: "Safe-area sub-label in the Display category — left inset."), value: "0.0"),
                    SignalEntry(label: String(localized: "bottom", comment: "Safe-area sub-label in the Display category — bottom inset."), value: "0.0"),
                    SignalEntry(label: String(localized: "right", comment: "Safe-area sub-label in the Display category — right inset."), value: "0.0"),
                  ]),
        ]
    }

    private static var locale: [FingerprintSignal] {
        [
            .make("identifier", category: .locale,
                  name: String(localized: "Locale.identifier"),
                  value: "en_CA@calendar=gregorian",
                  rationale: String(localized: "Locale string (e.g., `en_US@calendar=gregorian`) combining language, region, and calendar.")),
            .make("firstDayOfWeek", category: .locale,
                  name: String(localized: "First day of week"),
                  value: "sun",
                  rationale: String(localized: "Your preferred first day of the week. May differ from your region's default.")),
            .make("hourCycle", category: .locale,
                  name: String(localized: "Hour cycle"),
                  value: "h12",
                  rationale: String(localized: "Your preferred time format: 12-hour or 24-hour.")),
            .make("preferredLanguages", category: .locale,
                  name: String(localized: "Preferred languages"),
                  value: "en-CA, ar-CA, ja-CA",
                  rationale: String(localized: "Ordered list of preferred languages."),
                  displayHint: .tags,
                  entries: ["en-CA", "ar-CA", "ja-CA"].map { SignalEntry(label: $0, value: "") }),
            .make("tz.identifier", category: .locale,
                  name: String(localized: "Time zone identifier"),
                  value: "America/Toronto",
                  rationale: String(localized: "Time zone identifier (e.g., `Europe/Berlin`).")),
            .make("calendar", category: .locale,
                  name: String(localized: "Calendar"),
                  value: "gregorian",
                  rationale: String(localized: "Preferred calendar system (e.g., Gregorian, Islamic, Buddhist).")),
            .make("keyboards", category: .locale,
                  name: String(localized: "Keyboard languages"),
                  value: "en-CA, ar, ja-JP",
                  rationale: String(localized: "Enabled keyboard languages in order."),
                  displayHint: .tags,
                  entries: ["en-CA", "ar", "ja-JP"].map { SignalEntry(label: $0, value: "") }),
        ]
    }

    private static var accessibility: [FingerprintSignal] {
        [
            .make("voiceOverRunning", category: .accessibility,
                  name: String(localized: "VoiceOver running"), value: "false",
                  rationale: String(localized: "Whether the VoiceOver screen reader is active.")),
            .make("switchControlRunning", category: .accessibility,
                  name: String(localized: "Switch Control running"), value: "false",
                  rationale: String(localized: "Whether Switch Control is active.")),
            .make("guidedAccessEnabled", category: .accessibility,
                  name: String(localized: "Guided Access active"), value: "false",
                  rationale: String(localized: "Whether Guided Access is active.")),
            .make("grayscaleEnabled", category: .accessibility,
                  name: String(localized: "Grayscale color filter"), value: "false",
                  rationale: String(localized: "Whether the grayscale color filter is on.")),
            .make("invertColorsEnabled", category: .accessibility,
                  name: String(localized: "Invert Colors"), value: "false",
                  rationale: String(localized: "Whether Classic Invert Colors is on.")),
            .make("reduceMotionEnabled", category: .accessibility,
                  name: String(localized: "Reduce Motion"), value: "false",
                  rationale: String(localized: "Whether Reduce Motion is on.")),
            .make("activeFlags", category: .accessibility,
                  name: String(localized: "Other active flags"),
                  value: "BoldText, IncreaseContrast",
                  rationale: String(localized: "Additional accessibility flags any app can check. Each one you've turned on adds a distinguishing detail.")),
            .make("userInterfaceStyle", category: .accessibility,
                  name: String(localized: "userInterfaceStyle"), value: "dark",
                  rationale: String(localized: "Light or dark mode preference.")),
            .make("accessibilityContrast", category: .accessibility,
                  name: String(localized: "accessibilityContrast"), value: "high",
                  rationale: String(localized: "Whether Increase Contrast is on.")),
        ]
    }

    private static var deviceMotion: [FingerprintSignal] {
        [
            .make("accelerometer", category: .deviceMotion,
                  name: String(localized: "Accelerometer (g)"),
                  value: "x=-0.0084  y=-0.7621  z=-0.6487",
                  rationale: String(localized: "3-axis acceleration in g."),
                  displayHint: .axis,
                  entries: axis("-0.0084", "-0.7621", "-0.6487")),
            .make("gyroscope", category: .deviceMotion,
                  name: String(localized: "Gyroscope, raw (rad/s)"),
                  value: "x=+0.0021  y=-0.0009  z=+0.0014",
                  rationale: String(localized: "3-axis rotation rate in rad/s (uncalibrated)."),
                  displayHint: .axis,
                  entries: axis("+0.0021", "-0.0009", "+0.0014")),
            .make("magnetometer", category: .deviceMotion,
                  name: String(localized: "Magnetometer, raw (µT)"),
                  value: "x=+12.41  y=-38.07  z=+5.92",
                  rationale: String(localized: "3-axis magnetic field in µT (uncalibrated)."),
                  displayHint: .axis,
                  entries: axis("+12.41", "-38.07", "+5.92")),
            .make("attitude", category: .deviceMotion,
                  name: String(localized: "Attitude (°)"),
                  value: "r=+1.84  p=+49.62  y=-112.07",
                  rationale: String(localized: "Fused orientation as roll, pitch, and yaw in degrees."),
                  displayHint: .axis,
                  entries: [
                    SignalEntry(label: String(localized: "Roll", comment: "Attitude sub-label in the Device Motion category — roll axis in degrees."), value: "+1.84"),
                    SignalEntry(label: String(localized: "Pitch", comment: "Attitude sub-label in the Device Motion category — pitch axis in degrees."), value: "+49.62"),
                    SignalEntry(label: String(localized: "Yaw", comment: "Attitude sub-label in the Device Motion category — yaw axis in degrees."), value: "-112.07"),
                  ]),
            .make("gravity", category: .deviceMotion,
                  name: String(localized: "Gravity (g)"),
                  value: "x=-0.0091  y=-0.7615  z=-0.6481",
                  rationale: String(localized: "Gravity vector in g, separated from user-induced acceleration by the system."),
                  displayHint: .axis,
                  entries: axis("-0.0091", "-0.7615", "-0.6481")),
            .make("heading", category: .deviceMotion,
                  name: String(localized: "Compass heading"),
                  value: "247.6°",
                  rationale: String(localized: "Compass bearing in degrees relative to magnetic north.")),
        ]
    }

    private static var battery: [FingerprintSignal] {
        [
            .make("batteryLevel", category: .battery,
                  name: String(localized: "Battery level & state"),
                  value: "0.87 / charging",
                  rationale: String(localized: "Battery charge level and charging state. Changes slowly, so the value can persist across short sessions."),
                  displayHint: .compound,
                  entries: [
                    SignalEntry(label: String(localized: "Level"), value: "0.87"),
                    SignalEntry(label: String(localized: "State"), value: "charging"),
                  ]),
            .make("lowPowerMode", category: .battery,
                  name: String(localized: "Low power mode"), value: "false",
                  rationale: String(localized: "Whether you have Low Power Mode turned on.")),
            .make("thermalState", category: .battery,
                  name: String(localized: "Thermal state"), value: "nominal",
                  rationale: String(localized: "Current thermal state. Can reflect workload or charging.")),
        ]
    }

    private static var storage: [FingerprintSignal] {
        [
            .make("total", category: .storage,
                  name: String(localized: "Total capacity"),
                  value: "512 GB (512,000,000,000 bytes)",
                  rationale: String(localized: "Total storage on your \(PlatformDevice.localizedModel)")),
            .make("available", category: .storage,
                  name: String(localized: "Available capacity"),
                  value: "187.3 GB (187,283,316,736 bytes)",
                  rationale: String(localized: "Free space on your \(PlatformDevice.localizedModel). It changes slowly, so similar values across sessions can be correlated to one another.")),
            .make("reclaimable", category: .storage,
                  name: String(localized: "Reclaimable capacity"),
                  value: "important: 198.4 GB / opportunistic: 201.7 GB",
                  rationale: String(localized: "These APIs report free space including purgeable caches. The gap between them shows how much space the system could free up if asked."),
                  displayHint: .compound,
                  entries: [
                    SignalEntry(label: String(localized: "Important"), value: "198.4 GB"),
                    SignalEntry(label: String(localized: "Opportunistic"), value: "201.7 GB"),
                  ]),
            .make("created", category: .storage,
                  name: String(localized: "Volume creation date"),
                  value: "2026-05-14T19:58:10Z",
                  rationale: String(localized: "When your \(PlatformDevice.localizedModel) was first set up or last erased.")),
            .make("uuid", category: .storage,
                  name: String(localized: "Volume UUID"),
                  value: "B6E5A3C1-7F90-4D2E-A1B2-C3D4E5F60718",
                  rationale: String(localized: "Volume identifier. Appears to be identical across all iOS and iPadOS devices, so on its own it can't single you out.")),
            .make("name", category: .storage,
                  name: String(localized: "Volume name"),
                  value: "Data",
                  rationale: String(localized: "Appears to be identical across all iOS and iPadOS devices.")),
        ]
    }

    private static var network: [FingerprintSignal] {
        [
            .make("hostname", category: .network,
                  name: String(localized: "Local hostname"), value: deviceNoun,
                  rationale: String(localized: "The system's local hostname. Usually matches your device name.")),
            .make("isExpensive", category: .network,
                  name: String(localized: "isExpensive"), value: "false",
                  rationale: String(localized: "Whether the current connection is considered expensive (typically cellular).")),
            .make("isConstrained", category: .network,
                  name: String(localized: "isConstrained"), value: "false",
                  rationale: String(localized: "Whether Low Data Mode is on.")),
            .make("availableInterfaces", category: .network,
                  name: String(localized: "Available interfaces"),
                  value: "wifi, cellular",
                  rationale: String(localized: "Network interface types present (e.g., cellular, Wi-Fi, wired)."),
                  displayHint: .tags,
                  entries: ["wifi", "cellular"].map { SignalEntry(label: $0, value: "") }),
            .make("vpnActive", category: .network,
                  name: String(localized: "VPN active (heuristic)"), value: "false",
                  rationale: String(localized: "Checks for VPN-related interface names (tap, tun, ipsec) in system proxy settings.")),
            .make("addr.0.en0.IPv4", category: .network,
                  name: "en0 IPv4", value: "192.168.1.42",
                  rationale: String(localized: "Network interface address (local IP or cellular IP).")),
            .make("addr.1.en0.IPv6", category: .network,
                  name: "en0 IPv6", value: "fe80::18d4:9a21:7c3e:b1f2",
                  rationale: String(localized: "Network interface address (local IP or cellular IP).")),
        ]
    }

    private static var fonts: [FingerprintSignal] {
        let families = [
            "Academy Engraved LET", "Al Nile", "Apple Color Emoji", "Arial",
            "Avenir Next", "Baskerville", "Bodoni 72", "Chalkboard SE",
            "Courier New", "Damascus", "Futura", "Geeza Pro", "Georgia",
            "Helvetica Neue", "Hiragino Sans", "Menlo", "Palatino",
            "SF Pro", "Snell Roundhand", "Times New Roman", "Verdana", "Zapfino",
        ]
        return [
            .make("familyCount", category: .fonts,
                  name: String(localized: "Installed font families"),
                  value: "82",
                  rationale: String(localized: "Number of font families installed. A count above the system default usually means you've added custom fonts.")),
            .make("familiesAll", category: .fonts,
                  name: String(localized: "All families"),
                  value: families.joined(separator: ", "),
                  rationale: String(localized: "Full list of available font families."),
                  displayHint: .tags,
                  entries: families.map { SignalEntry(label: $0, value: "") }),
        ]
    }

    private static var voices: [FingerprintSignal] {
        let langs = ["ar-SA", "en-CA", "en-US", "ja-JP"]
        return [
            .make("count", category: .voices,
                  name: String(localized: "Installed voices"), value: "51",
                  rationale: String(localized: "Number of available text-to-speech voices. Higher counts usually mean you've downloaded Enhanced or Premium voices.")),
            .make("languages", category: .voices,
                  name: String(localized: "Voice languages"),
                  value: langs.joined(separator: ", "),
                  rationale: String(localized: "Language tags covered by the installed voices."),
                  displayHint: .keyValue,
                  entries: [
                    SignalEntry(label: "Arabic (Saudi Arabia)", value: "ar-SA"),
                    SignalEntry(label: "English (Canada)", value: "en-CA"),
                    SignalEntry(label: "English (United States)", value: "en-US"),
                    SignalEntry(label: "Japanese (Japan)", value: "ja-JP"),
                  ]),
            .make("downloaded", category: .voices,
                  name: String(localized: "Enhanced / Premium voices"),
                  value: "2: Ava, Kyoko",
                  rationale: String(localized: "Voices you've explicitly downloaded. Most devices have none of these."),
                  displayHint: .keyValue,
                  entries: [
                    SignalEntry(label: "Ava (en-US)", value: String(localized: "Premium")),
                    SignalEntry(label: "Kyoko (ja-JP)", value: String(localized: "Enhanced")),
                  ]),
        ]
    }

    private static var appInfo: [FingerprintSignal] {
        [
            .make("buildStamp", category: .appInfo,
                  name: String(localized: "Build stamp"),
                  value: "1.2 (40) / iphoneos26.4",
                  rationale: String(localized: "This app's build metadata: version, build, and the SDK it was compiled against.")),
            .make("installDate", category: .appInfo,
                  name: String(localized: "Install date"),
                  value: "2026-05-21T09:14:02Z",
                  rationale: String(localized: "Creation date of the app's Documents folder. Indicates when the app was installed.")),
        ]
    }

    private static var pasteboard: [FingerprintSignal] {
        [
            .make("changeCount", category: .pasteboard,
                  name: String(localized: "changeCount"), value: "3256",
                  rationale: String(localized: "Increments each time the pasteboard changes. The same counter is visible to every app.")),
            .make("hasStrings", category: .pasteboard,
                  name: String(localized: "hasStrings"), value: "true",
                  rationale: String(localized: "Whether the pasteboard contains text. Readable without triggering the \"pasted from\" banner.")),
            .make("hasURLs", category: .pasteboard,
                  name: String(localized: "hasURLs"), value: "true",
                  rationale: String(localized: "Whether the pasteboard contains a URL.")),
            .make("hasImages", category: .pasteboard,
                  name: String(localized: "hasImages"), value: "false",
                  rationale: String(localized: "Whether the pasteboard contains an image.")),
            .make("hasColors", category: .pasteboard,
                  name: String(localized: "hasColors"), value: "false",
                  rationale: String(localized: "Whether the pasteboard contains a color value.")),
            .make("numberOfItems", category: .pasteboard,
                  name: String(localized: "numberOfItems"), value: "1",
                  rationale: String(localized: "Number of items on the pasteboard.")),
        ]
    }

    private static var audioRoute: [FingerprintSignal] {
        [
            .make("outputs", category: .audioRoute,
                  name: String(localized: "Current outputs"),
                  value: "BluetoothA2DPOutput:Talal's AirPods Pro",
                  rationale: String(localized: "Output ports and their names (e.g., paired AirPods, AirPlay receivers)."),
                  displayHint: .keyValue,
                  entries: [SignalEntry(label: "Talal's AirPods Pro", value: "BluetoothA2DPOutput")]),
            .make("inputs", category: .audioRoute,
                  name: String(localized: "Current inputs"),
                  value: "MicrophoneBuiltIn:\(deviceNoun) Microphone",
                  rationale: String(localized: "Connected input hardware (built-in, headset, or accessory microphone)."),
                  displayHint: .keyValue,
                  entries: [SignalEntry(label: "\(deviceNoun) Microphone", value: "MicrophoneBuiltIn")]),
            .make("sampleRate", category: .audioRoute,
                  name: String(localized: "Hardware sample rate"), value: "48000 Hz",
                  rationale: String(localized: "The current hardware sample rate.")),
            .make("outputVolume", category: .audioRoute,
                  name: String(localized: "Output volume"), value: "0.44",
                  rationale: String(localized: "Current system output volume (0.0 to 1.0).")),
        ]
    }

    private static var metal: [FingerprintSignal] {
        let families = ["apple1", "apple2", "apple3", "apple4", "apple5", "apple6", "apple7", "apple8", "apple9", "common1", "common2", "common3", "metal3"]
        return [
            .make("name", category: .metal,
                  name: String(localized: "GPU name"), value: gpuName,
                  rationale: String(localized: "GPU name as Metal reports it (e.g., `Apple A18 Pro GPU`).")),
            .make("recommendedMax", category: .metal,
                  name: String(localized: "Recommended max working set"), value: "5.33 GB",
                  rationale: String(localized: "How much GPU memory the system suggests apps target.")),
            .make("raytracing", category: .metal,
                  name: String(localized: "Supports raytracing"), value: "true",
                  rationale: String(localized: "Whether your \(PlatformDevice.localizedModel)'s GPU supports hardware ray tracing.")),
            .make("families", category: .metal,
                  name: String(localized: "Supported families"),
                  value: families.joined(separator: ", "),
                  rationale: String(localized: "Metal GPU families this hardware supports."),
                  displayHint: .tags,
                  entries: families.map { SignalEntry(label: $0, value: "") }),
        ]
    }

    private static var telephony: [FingerprintSignal] {
        [
            .make("simCount", category: .telephony,
                  name: String(localized: "Active services"), value: "2",
                  rationale: String(localized: "Number of active cellular services (e.g., dual SIM).")),
            .make("rat.0", category: .telephony,
                  name: String(localized: "Radio tech [\("000000")…]"), value: "NRNSA",
                  rationale: String(localized: "Radio access technology (e.g., LTE, 5G) for this service.")),
            .make("rat.1", category: .telephony,
                  name: String(localized: "Radio tech [\("000001")…]"), value: "LTE",
                  rationale: String(localized: "Radio access technology (e.g., LTE, 5G) for this service.")),
        ]
    }

    // MARK: - Advanced categories

    private static var installedApps: [FingerprintSignal] {
        let allNames = InstalledAppsProvider.probes.map(\.name)
        let installed = allNames.filter { detectedApps.contains($0) }
        let missing = allNames.filter { !detectedApps.contains($0) }
        return [
            .make("installed", category: .installedApps,
                  name: String(localized: "Detected apps"),
                  value: "\(installed.count) of \(allNames.count): \(installed.joined(separator: ", "))",
                  rationale: String(localized: "Detected by calling `canOpenURL` against each URL scheme."),
                  displayHint: .tags,
                  entries: installed.map { SignalEntry(label: $0, value: "") }),
            .make("missing", category: .installedApps,
                  name: String(localized: "Missing apps"),
                  value: missing.joined(separator: ", "),
                  rationale: String(localized: "Apps from the same list where `canOpenURL` returned `false`."),
                  displayHint: .tags,
                  entries: missing.map { SignalEntry(label: $0, value: "") }),
        ]
    }

    private static var webViewFingerprint: [FingerprintSignal] {
        [
            .make("userAgent", category: .webViewFingerprint,
                  name: String(localized: "navigator.userAgent"),
                  value: webUserAgent,
                  rationale: String(localized: "Default user agent string. Includes device class and WebKit version.")),
            .make("platform", category: .webViewFingerprint,
                  name: String(localized: "navigator.platform"), value: deviceNoun,
                  rationale: String(localized: "Platform string reported by the browser (e.g., 'iPhone', 'iPad').")),
            .make("languages", category: .webViewFingerprint,
                  name: String(localized: "navigator.languages"),
                  value: "[\"en-CA\",\"ar\",\"ja\"]",
                  rationale: String(localized: "Preferred languages as reported by the browser.")),
            .make("hardwareConcurrency", category: .webViewFingerprint,
                  name: String(localized: "navigator.hardwareConcurrency"), value: "6",
                  rationale: String(localized: "Logical CPU core count as reported to JavaScript.")),
            .make("deviceMemory", category: .webViewFingerprint,
                  name: String(localized: "navigator.deviceMemory"), value: "8",
                  rationale: String(localized: "Approximate device memory as reported to JavaScript.")),
            .make("timezoneOffset", category: .webViewFingerprint,
                  name: String(localized: "Date.getTimezoneOffset"), value: "240",
                  rationale: String(localized: "Time zone offset in minutes as reported by JavaScript.")),
            .make("screen", category: .webViewFingerprint,
                  name: String(localized: "screen (JS)"),
                  value: "{\"w\":440,\"h\":956,\"d\":3,\"cd\":24}",
                  rationale: String(localized: "Screen dimensions and pixel ratio as reported by JavaScript.")),
            .make("canvasHash", category: .webViewFingerprint,
                  name: String(localized: "Canvas fingerprint"),
                  value: "a3f9c1e07b24d8650f1a2b3c4d5e6f70",
                  rationale: String(localized: "Hash of a rendered 2D canvas. Varies by GPU and WebKit version.")),
            .make("webgl", category: .webViewFingerprint,
                  name: String(localized: "WebGL renderer"),
                  value: "Apple Inc. | Apple GPU",
                  rationale: String(localized: "GPU renderer string reported by WebGL.")),
        ]
    }

    private static var previousInstalls: [FingerprintSignal] {
        [
            .make("installCount", category: .previousInstalls,
                  name: String(localized: "Install count"), value: "3",
                  rationale: String(localized: "Number of times this app has been installed. Keychain entries persist across uninstalls.")),
            .make("firstInstall", category: .previousInstalls,
                  name: String(localized: "First install date"),
                  value: "2026-02-08T17:42:55Z",
                  rationale: String(localized: "Earliest recorded install date. Persists in the Keychain across uninstalls.")),
            .make("currentInstall", category: .previousInstalls,
                  name: String(localized: "Current install date"),
                  value: "2026-05-21T09:14:02Z",
                  rationale: String(localized: "First launch date of the current installation.")),
            .make("installLog", category: .previousInstalls,
                  name: String(localized: "Install history"),
                  value: "2026-02-08T17:42:55Z, 2026-04-02T11:08:30Z, 2026-05-21T09:14:02Z",
                  rationale: String(localized: "Timestamps of each recorded installation.")),
        ]
    }

    // MARK: - Permissioned categories

    private static var motion: [FingerprintSignal] {
        [
            .make("activity", category: .motion,
                  name: String(localized: "Current activity"),
                  value: "walking  conf=high",
                  rationale: String(localized: "Activity classification (e.g., walking, running) and confidence level."),
                  displayHint: .compound,
                  entries: [
                    SignalEntry(label: String(localized: "Activity"), value: "walking"),
                    SignalEntry(label: String(localized: "Confidence"), value: "high"),
                  ]),
            .make("altimeter.pressure", category: .motion,
                  name: String(localized: "Air pressure (kPa)"), value: "100.8412",
                  rationale: String(localized: "Barometric pressure reading.")),
            .make("altimeter.relativeAltitude", category: .motion,
                  name: String(localized: "Relative altitude (m)"), value: "+3.42",
                  rationale: String(localized: "Change in altitude since the sensor started.")),
            .make("altimeter.absoluteAltitude", category: .motion,
                  name: String(localized: "Absolute altitude (m)"), value: "104.27",
                  rationale: String(localized: "Estimated absolute altitude above sea level.")),
            .make("pedometer.steps", category: .motion,
                  name: String(localized: "Steps today"), value: "6432",
                  rationale: String(localized: "Estimated step count for today.")),
            .make("pedometer.distance", category: .motion,
                  name: String(localized: "Distance today (m)"), value: "4821.6",
                  rationale: String(localized: "Estimated distance traveled today.")),
            .make("pedometer.floorsUp", category: .motion,
                  name: String(localized: "Floors ascended"), value: "7",
                  rationale: String(localized: "Estimated floors ascended today.")),
        ]
    }

    private static var location: [FingerprintSignal] {
        [
            .make("authorization", category: .location,
                  name: String(localized: "Authorization"), value: "authorizedWhenInUse",
                  rationale: String(localized: "Location authorization status.")),
            .make("accuracyAuthorization", category: .location,
                  name: String(localized: "Accuracy authorization"), value: "full",
                  rationale: String(localized: "Precise or Reduced accuracy. Determines the granularity of reported coordinates.")),
            .make("coordinate", category: .location,
                  name: String(localized: "Coordinate"), value: "43.65107, -79.34738",
                  rationale: String(localized: "Your latitude and longitude. With Reduced accuracy, this is a general area rather than a precise point.")),
            .make("altitude", category: .location,
                  name: String(localized: "Altitude (m)"), value: "104.3",
                  rationale: String(localized: "Altitude above sea level.")),
            .make("horizontalAccuracy", category: .location,
                  name: String(localized: "Horizontal accuracy"), value: "5.0 m",
                  rationale: String(localized: "Precision of the coordinate. Larger values mean less certainty.")),
            .make("speed", category: .location,
                  name: String(localized: "Speed"), value: "1.32 m/s",
                  rationale: String(localized: "Current speed. A value of -1 means unknown.")),
            .make("course", category: .location,
                  name: String(localized: "Course"), value: "247.6°",
                  rationale: String(localized: "Direction of travel. A value of -1 means unknown.")),
        ]
    }

    private static var camera: [FingerprintSignal] {
        [
            .make("deviceCount", category: .camera,
                  name: String(localized: "Camera count"), value: "9",
                  rationale: String(localized: "Number of cameras on your \(PlatformDevice.localizedModel). The count also includes \"virtual\" cameras that simulate various focal lengths.")),
            .make("cam.0.type", category: .camera,
                  name: String(localized: "Camera \(0)"),
                  value: "Back Triple Camera (back) · FOV 73°",
                  rationale: String(localized: "Lens type, position, and field of view.")),
            .make("cam.1.type", category: .camera,
                  name: String(localized: "Camera \(1)"),
                  value: "Back Ultra Wide Camera (back) · FOV 120°",
                  rationale: String(localized: "Lens type, position, and field of view.")),
            .make("cam.2.type", category: .camera,
                  name: String(localized: "Camera \(2)"),
                  value: "Front TrueDepth Camera (front) · FOV 88°",
                  rationale: String(localized: "Lens type, position, and field of view.")),
        ]
    }

    private static var bluetooth: [FingerprintSignal] {
        let peripherals: [(String, String)] = [
            ("Talal's AirPods Pro", "-41 dBm"),
            ("Apple Watch Ultra 2", "-52 dBm"),
            ("Living Room TV", "-63 dBm"),
            ("Tesla Model 3", "-66 dBm"),
            ("Mi Band 8", "-71 dBm"),
            ("Sony WH-1000XM5", "-74 dBm"),
            ("Kitchen Hue lamp", "-78 dBm"),
            ("Bedroom Hue lamp", "-81 dBm"),
            ("LE-Bose SoundLink", "-86 dBm"),
            ("Logitech MX Keys", "-89 dBm"),
        ]
        return [
            .make("peripherals", category: .bluetooth,
                  name: String(localized: "BLE peripherals (5s scan)"),
                  value: peripherals.map { "\($0.0) (\($0.1))" }.joined(separator: "\n"),
                  rationale: String(localized: "BLE device names and signal strength discovered during a brief scan."),
                  displayHint: .keyValue,
                  entries: peripherals.map { SignalEntry(label: $0.0, value: $0.1) }),
        ]
    }

    private static var localNetwork: [FingerprintSignal] {
        // Sorted by service id, matching the live provider's ordering.
        [
            .make("svc._airplay._tcp", category: .localNetwork,
                  name: String(localized: "AirPlay receivers", comment: "Bonjour service type label in the Local Network category."),
                  value: "Living Room, Bedroom TV, Office Apple TV",
                  rationale: ""),
            .make("svc._companion-link._tcp", category: .localNetwork,
                  name: String(localized: "Companion link (Apple)", comment: "Bonjour service type label in the Local Network category."),
                  value: "Talal's MacBook Pro, Talal's iPad, Talal's Apple Watch",
                  rationale: ""),
            .make("svc._googlecast._tcp", category: .localNetwork,
                  name: String(localized: "Google Cast", comment: "Bonjour service type label in the Local Network category."),
                  value: "Office Nest Hub, Garage Chromecast",
                  rationale: ""),
            .make("svc._hap._tcp", category: .localNetwork,
                  name: String(localized: "HAP (HomeKit protocol)", comment: "Bonjour service type label in the Local Network category."),
                  value: "Front Door Lock, Thermostat, Hallway Sensor",
                  rationale: ""),
            .make("svc._homekit._tcp", category: .localNetwork,
                  name: String(localized: "HomeKit accessories", comment: "Bonjour service type label in the Local Network category."),
                  value: "Hue Bridge, Eve Energy, Aqara Hub",
                  rationale: ""),
            .make("svc._hue._tcp", category: .localNetwork,
                  name: String(localized: "Philips Hue bridges", comment: "Bonjour service type label in the Local Network category."),
                  value: "Hue Bridge",
                  rationale: ""),
            .make("svc._ipp._tcp", category: .localNetwork,
                  name: String(localized: "IPP printers", comment: "Bonjour service type label in the Local Network category."),
                  value: "HP OfficeJet Pro",
                  rationale: ""),
            .make("svc._matter._tcp", category: .localNetwork,
                  name: String(localized: "Matter smart home", comment: "Bonjour service type label in the Local Network category."),
                  value: "Living Room Plug, Desk Lamp",
                  rationale: ""),
            .make("svc._printer._tcp", category: .localNetwork,
                  name: String(localized: "Printers", comment: "Bonjour service type label in the Local Network category."),
                  value: "HP OfficeJet Pro, Brother HL-L2350DW",
                  rationale: ""),
            .make("svc._raop._tcp", category: .localNetwork,
                  name: String(localized: "AirPlay audio (RAOP)", comment: "Bonjour service type label in the Local Network category."),
                  value: "Living Room, Kitchen, HomePod mini",
                  rationale: ""),
            .make("svc._sonos._tcp", category: .localNetwork,
                  name: String(localized: "Sonos speakers", comment: "Bonjour service type label in the Local Network category."),
                  value: "Kitchen, Living Room, Bedroom",
                  rationale: ""),
            .make("svc._spotify-connect._tcp", category: .localNetwork,
                  name: String(localized: "Spotify Connect", comment: "Bonjour service type label in the Local Network category."),
                  value: "Kitchen Sonos, Office Nest Hub",
                  rationale: ""),
        ]
    }

    private static var contacts: [FingerprintSignal] {
        [
            .make("containerCount", category: .contacts,
                  name: String(localized: "Container count"), value: "2",
                  rationale: String(localized: "Number of contact sources (e.g., iCloud, local, Exchange).")),
            .make("total", category: .contacts,
                  name: String(localized: "Contact count"), value: "428",
                  rationale: String(localized: "Total number of contacts.")),
            .make("phoneCount", category: .contacts,
                  name: String(localized: "Phone number count"), value: "612",
                  rationale: String(localized: "Total phone numbers across all contacts.")),
            .make("emailCount", category: .contacts,
                  name: String(localized: "Email count"), value: "377",
                  rationale: String(localized: "Total email addresses across all contacts.")),
            .make("postalCount", category: .contacts,
                  name: String(localized: "Postal address count"), value: "143",
                  rationale: String(localized: "Total postal addresses across all contacts.")),
            .make("phoneLabels", category: .contacts,
                  name: String(localized: "Phone number labels"),
                  value: "mobile:381, home:104, work:97, iPhone:30",
                  rationale: String(localized: "Labels used for phone numbers (e.g., mobile, home, work)."),
                  displayHint: .keyValue,
                  entries: [
                    SignalEntry(label: "mobile", value: "381"),
                    SignalEntry(label: "home", value: "104"),
                    SignalEntry(label: "work", value: "97"),
                    SignalEntry(label: "iPhone", value: "30"),
                  ]),
        ]
    }

    private static var photos: [FingerprintSignal] {
        [
            .make("imageCount", category: .photos,
                  name: String(localized: "Image count"), value: "12843",
                  rationale: String(localized: "Number of images accessible to the app.")),
            .make("videoCount", category: .photos,
                  name: String(localized: "Video count"), value: "938",
                  rationale: String(localized: "Number of videos accessible to the app.")),
            .make("audioCount", category: .photos,
                  name: String(localized: "Audio count"), value: "12",
                  rationale: String(localized: "Number of audio assets in the photo library.")),
            .make("userAlbumCount", category: .photos,
                  name: String(localized: "User albums"), value: "24",
                  rationale: String(localized: "User-created album count.")),
            .make("smartAlbumCount", category: .photos,
                  name: String(localized: "Smart albums"), value: "18",
                  rationale: String(localized: "System-generated album count.")),
            .make("sharedAlbumCount", category: .photos,
                  name: String(localized: "Shared albums"), value: "6",
                  rationale: String(localized: "Shared iCloud album count.")),
            .make("geotaggedCount", category: .photos,
                  name: String(localized: "Geotagged photos"), value: "9127",
                  rationale: String(localized: "Photos and videos with embedded GPS coordinates.")),
            .make("recentLocations", category: .photos,
                  name: String(localized: "Recent locations"),
                  value: recentPhotoLocations.joined(separator: ", "),
                  rationale: String(localized: "Locations from the most recently taken geotagged photos."),
                  displayHint: .tags,
                  entries: recentPhotoLocations.map { SignalEntry(label: $0, value: "") }),
            .make("frequentLocations", category: .photos,
                  name: String(localized: "Frequent locations"),
                  value: frequentPhotoLocations.map { "\($0.0) (\($0.1))" }.joined(separator: ", "),
                  rationale: String(localized: "Most common locations found across all geotagged photos."),
                  displayHint: .keyValue,
                  entries: frequentPhotoLocations.map { SignalEntry(label: $0.0, value: String($0.1)) }),
        ]
    }

    private static var calendar: [FingerprintSignal] {
        [
            .make("calendarCount", category: .calendar,
                  name: String(localized: "Calendar count"), value: "9",
                  rationale: String(localized: "Total calendars across all your accounts (iCloud, Exchange, Google, subscribed).")),
            .make("sourceCount", category: .calendar,
                  name: String(localized: "Source count"), value: "3",
                  rationale: String(localized: "Distinct calendar providers (e.g., iCloud, Gmail, Exchange).")),
            .make("sources", category: .calendar,
                  name: String(localized: "Sources"),
                  value: "Exchange, Gmail, iCloud",
                  rationale: String(localized: "Calendar provider names."),
                  displayHint: .tags,
                  entries: ["Exchange", "Gmail", "iCloud"].map { SignalEntry(label: $0, value: "") }),
            .make("types", category: .calendar,
                  name: String(localized: "Types"),
                  value: "birthday, calDAV, exchange, subscription",
                  rationale: String(localized: "Calendar types (local, CalDAV, Exchange, subscription, birthday)."),
                  displayHint: .tags,
                  entries: ["birthday", "calDAV", "exchange", "subscription"].map { SignalEntry(label: $0, value: "") }),
            .make("events60d", category: .calendar,
                  name: String(localized: "Events (±30 days)"), value: "37",
                  rationale: String(localized: "Event count within a 60-day window around today.")),
        ]
    }

    private static var reminders: [FingerprintSignal] {
        [
            .make("listCount", category: .reminders,
                  name: String(localized: "Reminder lists"), value: "5",
                  rationale: String(localized: "Number of reminder lists.")),
            .make("listTitles", category: .reminders,
                  name: String(localized: "List titles"),
                  value: "Groceries, Work, Reading List, Travel, Home",
                  rationale: String(localized: "Reminder list names.")),
            .make("incomplete", category: .reminders,
                  name: String(localized: "Incomplete reminders"), value: "23",
                  rationale: String(localized: "Total incomplete reminders. Individual titles are not accessed.")),
        ]
    }

    private static var musicLibrary: [FingerprintSignal] {
        [
            .make("songCount", category: .musicLibrary,
                  name: String(localized: "Songs"), value: "2184",
                  rationale: String(localized: "Total songs in the local music library.")),
            .make("albumCount", category: .musicLibrary,
                  name: String(localized: "Albums"), value: "196",
                  rationale: String(localized: "Total albums represented in the library.")),
            .make("playlistCount", category: .musicLibrary,
                  name: String(localized: "Playlists"), value: "31",
                  rationale: String(localized: "Total playlists, including smart and user-made.")),
            .make("artistCount", category: .musicLibrary,
                  name: String(localized: "Artists"), value: "318",
                  rationale: String(localized: "Distinct artist count.")),
            .make("topGenres", category: .musicLibrary,
                  name: String(localized: "Top genres"),
                  value: "Hip-Hop/Rap (514), Electronic (302), Alternative (221)",
                  rationale: String(localized: "Most common genres by song count."),
                  displayHint: .keyValue,
                  entries: [
                    SignalEntry(label: "Hip-Hop/Rap", value: "514"),
                    SignalEntry(label: "Electronic", value: "302"),
                    SignalEntry(label: "Alternative", value: "221"),
                  ]),
            .make("topArtists", category: .musicLibrary,
                  name: String(localized: "Top artists"),
                  value: "Fairuz (98), Kendrick Lamar (76), Daft Punk (54)",
                  rationale: String(localized: "Artists with the most songs in your library."),
                  displayHint: .keyValue,
                  entries: [
                    SignalEntry(label: "Fairuz", value: "98"),
                    SignalEntry(label: "Kendrick Lamar", value: "76"),
                    SignalEntry(label: "Daft Punk", value: "54"),
                  ]),
            .make("recentlyAdded", category: .musicLibrary,
                  name: String(localized: "Added in last 30 days"), value: "41",
                  rationale: String(localized: "Songs added in the last 30 days.")),
            .make("appleMusic", category: .musicLibrary,
                  name: String(localized: "Apple Music capabilities"),
                  value: "catalog playback, iCloud Music Library",
                  rationale: String(localized: "Your Apple Music subscription and iCloud Music Library state.")),
        ]
    }

    // MARK: - Photo geotag data

    /// Most recently taken geotagged photo locations (recency order),
    /// hinting at a recent trip mixed with the persona's home turf.
    private static let recentPhotoLocations: [String] = [
        "El Born, Barcelona",
        "La Rambla, Barcelona",
        "Montmartre, Paris",
        "Trastevere, Rome",
        "Shibuya, Tokyo",
        "Kyoto, Kyoto Prefecture",
        "YVR, Richmond, BC",
        "The Annex, Toronto, ON",
        "Old Toronto, ON",
        "Le Plateau, Montréal, QC",
    ]

    /// Most photographed locations across the whole library (count order),
    /// dominated by home, work, and frequent haunts.
    private static let frequentPhotoLocations: [(String, Int)] = [
        ("The Annex, Toronto, ON", 2841),
        ("Old Toronto, ON", 1290),
        ("Kensington Market, Toronto, ON", 712),
        ("Liberty Village, Toronto, ON", 488),
        ("Le Plateau, Montréal, QC", 356),
        ("El Born, Barcelona", 318),
        ("Montmartre, Paris", 264),
        ("Trastevere, Rome", 197),
        ("Shibuya, Tokyo", 152),
        ("Banff, AB", 131),
    ]

    // MARK: - Helpers

    private static func axis(_ x: String, _ y: String, _ z: String) -> [SignalEntry] {
        [
            SignalEntry(label: "X", value: x),
            SignalEntry(label: "Y", value: y),
            SignalEntry(label: "Z", value: z),
        ]
    }
}
