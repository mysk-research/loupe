//
//  SignalCategory.swift
//  Loupe
//
//  The canonical list of fingerprinting surfaces the app exposes. Every
//  provider maps to exactly one case, and the UI iterates this enum to
//  build the home list. Order here is display order.
//

import Foundation

enum SignalCategory: String, Codable, Sendable, CaseIterable, Identifiable, Hashable {
    case deviceIdentity
    case systemInfo
    case battery
    case storage
    case display
    case audioRoute
    case locale
    case accessibility
    case pasteboard
    case deviceMotion
    case network
    case fonts
    case voices
    case appInfo
    case appleAccount
    case metal
    case telephony
    case installedApps
    case webViewFingerprint
    case previousInstalls
    case motion
    case location
    case camera
    case bluetooth
    case localNetwork
    case contacts
    case photos
    case calendar
    case reminders
    case musicLibrary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .deviceIdentity: return String(localized: "Device Identity", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .appleAccount: return String(localized: "Apple Account", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .systemInfo: return String(localized: "System Info", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .display: return String(localized: "Display", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .locale: return String(localized: "Locale & Region", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .accessibility: return String(localized: "Accessibility", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .deviceMotion: return String(localized: "Device Motion", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .battery: return String(localized: "Battery & Power", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .storage: return String(localized: "Storage", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .network: return String(localized: "Network", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .fonts: return String(localized: "Fonts", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .voices: return String(localized: "Installed Voices", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .appInfo: return String(localized: "App & Bundle", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .pasteboard: return String(localized: "Pasteboard", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .audioRoute: return String(localized: "Audio", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .metal: return String(localized: "Graphics & Metal", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .telephony: return String(localized: "Telephony", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .installedApps: return String(localized: "Installed Apps Probe", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .webViewFingerprint: return String(localized: "WebView Fingerprint", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .previousInstalls: return String(localized: "Previous Installs Log", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .motion: return String(localized: "Motion & Sensors", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .location: return String(localized: "Location", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .camera: return String(localized: "Cameras", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .bluetooth: return String(localized: "Bluetooth", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .localNetwork: return String(localized: "Local Network", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .contacts: return String(localized: "Contacts", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .photos: return String(localized: "Photos", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .calendar: return String(localized: "Calendar", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .reminders: return String(localized: "Reminders", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        case .musicLibrary: return String(localized: "Music", comment: "Category title shown in the home list, navigation bar, and as a heading on the per-category screen.")
        }
    }

    @MainActor
    var subtitle: String {
        switch self {
        case .deviceIdentity: return String(localized: "Vendor ID and hardware identifiers", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .appleAccount: return String(localized: "iCloud and App Store account signals", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .systemInfo: return String(localized: "Kernel, runtime, and OS state", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .display: return String(localized: "Screen specs and rendering capabilities", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .locale: return String(localized: "Language, region, and time settings", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .accessibility: return String(localized: "System accessibility flags", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .deviceMotion: return String(localized: "Accelerometer, gyro, and other motion sensors", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .battery: return String(localized: "Charge, power, and thermal state", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .storage: return String(localized: "Volume capacity and metadata", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .network: return String(localized: "Interfaces, addresses, and VPN signals", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .fonts: return String(localized: "Installed fonts", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .voices: return String(localized: "Installed text-to-speech voices", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .appInfo: return String(localized: "App build and install info", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .pasteboard: return String(localized: "Clipboard activity and content types", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .audioRoute: return String(localized: "Audio routes and capabilities", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .metal: return String(localized: "GPU details and capabilities", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .telephony: return String(localized: "Cellular service and radio info", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .installedApps: return String(localized: "App detection via URL schemes", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .webViewFingerprint: return String(localized: "Browser-style fingerprinting", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .previousInstalls: return String(localized: "Reinstall history kept in Keychain", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .motion: return String(localized: "Activity, steps, and altitude", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .location: return String(localized: "Coordinate and movement data", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .camera: return String(localized: "Camera lineup and capabilities", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .bluetooth: return String(localized: "Adapter state and nearby devices", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .localNetwork: return String(localized: "Bonjour scan for nearby services", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .contacts: return String(localized: "Address book metadata", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .photos: return String(localized: "Library counts, geotags, and locations", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .calendar: return String(localized: "Calendars, sources, and events", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .reminders: return String(localized: "Reminder lists and counts", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        case .musicLibrary: return String(localized: "Library counts and listening tastes", comment: "Category subtitle shown beneath the title in the home list. Brief description of what the category covers.")
        }
    }

    var symbolName: String {
        switch self {
        case .deviceIdentity: return "iphone.gen3"
        case .appleAccount: return "person.crop.circle.badge.checkmark"
        case .systemInfo: return "cpu"
        case .display: return "display"
        case .locale: return "globe.badge.chevron.backward"
        case .accessibility: return "accessibility"
        case .deviceMotion: return "gyroscope"
        case .battery: return "battery.100percent.bolt"
        case .storage: return "internaldrive"
        case .network: return "network"
        case .fonts: return "textformat"
        case .voices: return "waveform.and.person.filled"
        case .appInfo: return "app.badge"
        case .pasteboard: return "doc.on.clipboard"
        case .audioRoute: return "speaker.wave.2"
        case .metal: return "bolt.horizontal.circle"
        case .telephony: return "antenna.radiowaves.left.and.right"
        case .installedApps: return "square.grid.3x3"
        case .webViewFingerprint: return "safari"
        case .previousInstalls: return "arrow.counterclockwise.circle"
        case .motion: return "figure.walk"
        case .location: return "location.fill"
        case .camera: return "camera.aperture"
        case .bluetooth: return "dot.radiowaves.right"
        case .localNetwork: return "wifi.router"
        case .contacts: return "person.2.fill"
        case .photos: return "photo.stack"
        case .calendar: return "calendar"
        case .reminders: return "checklist"
        case .musicLibrary: return "music.note.list"
        }
    }

    var sensitivity: Sensitivity {
        switch self {
        case .installedApps, .webViewFingerprint, .previousInstalls:
            return .advanced
        case .motion, .location, .camera, .bluetooth,
            .localNetwork, .contacts, .photos, .calendar, .reminders, .musicLibrary:
            return .permissioned
        default:
            return .passive
        }
    }

    var permission: PermissionKind? {
        switch self {
        case .motion: return .motion
        case .location: return .location
        case .camera: return .camera
        case .bluetooth: return .bluetooth
        case .localNetwork: return .localNetwork
        case .contacts: return .contacts
        case .photos: return .photos
        case .calendar: return .calendar
        case .reminders: return .reminders
        case .musicLibrary: return .musicLibrary
        default: return nil
        }
    }

    /// An app-level consent the category asks for before part of its
    /// collection may run, beyond the iOS permission.
    var collectionConsent: CollectionConsent? {
        switch self {
        case .photos: return .photosGeocoding
        default: return nil
        }
    }
}
