//
//  PermissionKind.swift
//  Loupe
//
//  Describes which operating-system permission gate a category has to pass
//  before it can produce any signals.
//

import Foundation

enum PermissionKind: String, Codable, Sendable, CaseIterable, Identifiable {
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

    @MainActor
    var title: String {
        switch self {
        case .motion: return String(localized: "Motion & Fitness", comment: "Permission kind title shown on the permission gate screen and in the home list.")
        case .location: return String(localized: "Location", comment: "Permission kind title shown on the permission gate screen and in the home list.")
        case .camera: return String(localized: "Camera", comment: "Permission kind title shown on the permission gate screen and in the home list.")
        case .bluetooth: return String(localized: "Bluetooth", comment: "Permission kind title shown on the permission gate screen and in the home list.")
        case .localNetwork: return String(localized: "Local Network", comment: "Permission kind title shown on the permission gate screen and in the home list.")
        case .contacts: return String(localized: "Contacts", comment: "Permission kind title shown on the permission gate screen and in the home list.")
        case .photos: return String(localized: "Photos", comment: "Permission kind title shown on the permission gate screen and in the home list.")
        case .calendar: return String(localized: "Calendar", comment: "Permission kind title shown on the permission gate screen and in the home list.")
        case .reminders: return String(localized: "Reminders", comment: "Permission kind title shown on the permission gate screen and in the home list.")
        case .musicLibrary: return String(localized: "Media & Apple Music", comment: "Permission kind title shown on the permission gate screen and in the home list.")
        }
    }

    @MainActor
    var rationale: String {
        switch self {
        case .motion:
            return String(localized: "Motion sensors stream up to 100 readings a second, and the patterns can hint at how you walk.", comment: "Educational paragraph shown on the motion permission gate explaining what the permission can leak.")
        case .location:
            return String(localized: "A single coordinate reading can pin you to within a few meters. Altitude narrows it further, often down to a specific floor of a building.", comment: "Educational paragraph shown on the location permission gate explaining what the permission can leak.")
        case .camera:
            return String(localized: "The list of cameras on your \(PlatformDevice.localizedModel), with their focal lengths and apertures, often pinpoints the exact model.", comment: "Educational paragraph shown on the camera permission gate explaining what the permission can leak. %@ is the device model name (e.g., iPhone, iPad).")
        case .bluetooth:
            return String(localized: "Scanning for nearby Bluetooth devices reveals the speakers, headphones, watches, and other gear around you, often including their owners' names.", comment: "Educational paragraph shown on the bluetooth permission gate explaining what the permission can leak.")
        case .localNetwork:
            return String(localized: "Bonjour discovery lists the speakers, TVs, printers, and other devices on your Wi-Fi network. That inventory is often unique to your home.", comment: "Educational paragraph shown on the local network permission gate explaining what the permission can leak.")
        case .contacts:
            return String(localized: "The number of contacts and the labels you use (Mom, Spouse, Work) hint at your social circle and relationships.", comment: "Educational paragraph shown on the contacts permission gate explaining what the permission can leak.")
        case .photos:
            return String(localized: "Photo counts, album names, and the geotags embedded in your photos can reveal where you've been and where you spend most of your time, without an app needing to open a single image.", comment: "Educational paragraph shown on the photos permission gate explaining what the permission can leak.")
        case .calendar:
            return String(localized: "The number of events, the calendars you sync, and the sources behind them (iCloud, Exchange, Google) reflect your routine and the services you use.", comment: "Educational paragraph shown on the calendar permission gate explaining what the permission can leak.")
        case .reminders:
            return String(localized: "Your reminder lists, and the accounts they sync from, can identify which services and providers you rely on.", comment: "Educational paragraph shown on the reminders permission gate explaining what the permission can leak.")
        case .musicLibrary:
            return String(localized: "Music library counts and your most-played artists are taste signals that ad and recommendation networks pay for.", comment: "Educational paragraph shown on the music library permission gate explaining what the permission can leak.")
        }
    }
}
