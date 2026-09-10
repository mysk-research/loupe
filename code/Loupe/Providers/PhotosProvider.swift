//
//  PhotosProvider.swift
//  Loupe
//
//  Counts photo library items and collection buckets, and scans
//  geotagged assets for location summaries. Never asks for pixels
//  or full-resolution image data.
//

import CoreLocation
import Photos

@MainActor
struct PhotosProvider: SignalProvider {
    let category: SignalCategory = .photos
    let center: PermissionCenter

    func collect() async -> [FingerprintSignal] {
        var signals: [FingerprintSignal] = []
        let images = PHAsset.fetchAssets(with: .image, options: nil).count
        let videos = PHAsset.fetchAssets(with: .video, options: nil).count
        let audio = PHAsset.fetchAssets(with: .audio, options: nil).count
        
        let locationScan = await scanLocations()
        let lookupSkipped = !CollectionConsent.photosGeocoding.isEnabled && locationScan.geotagged > 0
        let notLookedUp = String(localized: "(not looked up)", comment: "Placeholder value shown on the Photos Recent/Frequent locations cards when place-name lookup is turned off.")
        signals.append(
            .make(
                "geotaggedCount",
                category: category,
                name: String(localized: "Geotagged photos", comment: "Signal card name in the Photos category — count of photos/videos with embedded GPS coordinates."),
                value: String(locationScan.geotagged),
                rationale: String(localized: "Photos and videos with embedded GPS coordinates.", comment: "Signal card rationale beneath the Geotagged photos value.")))
        let recentRationale = String(localized: "Locations from the most recently taken geotagged photos.", comment: "Signal card rationale beneath the Recent locations value.")
        signals.append(
            .make(
                "recentLocations",
                category: category,
                name: String(localized: "Recent locations", comment: "Signal card name in the Photos category — locations from the most recently taken geotagged photos."),
                value: locationScan.recent.isEmpty
                    ? (lookupSkipped
                        ? notLookedUp
                        : String(localized: "(none)", comment: "Placeholder value shown for the Recent locations card when no geotagged photos were found."))
                    : locationScan.recent,
                rationale: recentRationale,
                displayHint: locationScan.recentEntries.isEmpty ? .plain : .tags,
                entries: locationScan.recentEntries.isEmpty ? nil : locationScan.recentEntries))
        let frequentRationale = String(localized: "Most common locations found across all geotagged photos.", comment: "Signal card rationale beneath the Frequent locations value.")
        signals.append(
            .make(
                "frequentLocations",
                category: category,
                name: String(localized: "Frequent locations", comment: "Signal card name in the Photos category — most common locations across all geotagged photos."),
                value: locationScan.frequent.isEmpty
                    ? (lookupSkipped
                        ? notLookedUp
                        : String(localized: "(none)", comment: "Placeholder value shown for the Frequent locations card when no geotagged photos were found."))
                    : locationScan.frequent,
                rationale: frequentRationale,
                displayHint: locationScan.frequentEntries.isEmpty ? .plain : .keyValue,
                entries: locationScan.frequentEntries.isEmpty ? nil : locationScan.frequentEntries))

        signals.append(
            .make(
                "imageCount",
                category: category,
                name: String(localized: "Image count", comment: "Signal card name in the Photos category — total images accessible to the app."),
                value: String(images),
                rationale: String(localized: "Number of images accessible to the app.", comment: "Signal card rationale beneath the Image count value.")))
        signals.append(
            .make(
                "videoCount",
                category: category,
                name: String(localized: "Video count", comment: "Signal card name in the Photos category — total videos accessible to the app."),
                value: String(videos),
                rationale: String(localized: "Number of videos accessible to the app.", comment: "Signal card rationale beneath the Video count value.")))
        signals.append(
            .make(
                "audioCount",
                category: category,
                name: String(localized: "Audio count", comment: "Signal card name in the Photos category — total audio assets accessible to the app."),
                value: String(audio),
                rationale: String(localized: "Number of audio assets in the photo library.", comment: "Signal card rationale beneath the Audio count value.")))

        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil).count
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil).count
        let sharedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: nil).count
        signals.append(
            .make(
                "userAlbumCount",
                category: category,
                name: String(localized: "User albums", comment: "Signal card name in the Photos category — user-created album count."),
                value: String(userAlbums),
                rationale: String(localized: "User-created album count.", comment: "Signal card rationale beneath the User albums value.")))
        signals.append(
            .make(
                "smartAlbumCount",
                category: category,
                name: String(localized: "Smart albums", comment: "Signal card name in the Photos category — system-generated smart album count."),
                value: String(smartAlbums),
                rationale: String(localized: "System-generated album count.", comment: "Signal card rationale beneath the Smart albums value.")))
        signals.append(
            .make(
                "sharedAlbumCount",
                category: category,
                name: String(localized: "Shared albums", comment: "Signal card name in the Photos category — shared iCloud album count."),
                value: String(sharedAlbums),
                rationale: String(localized: "Shared iCloud album count.", comment: "Signal card rationale beneath the Shared albums value.")))

        return signals
    }

    // MARK: - Location scanning

    private func scanLocations() async -> (geotagged: Int, recent: String, frequent: String, recentEntries: [SignalEntry], frequentEntries: [SignalEntry]) {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: options)

        var geotaggedCount = 0
        // Grid key → count for frequency ranking
        var clusterCounts: [GridKey: Int] = [:]
        // Grid key → representative CLLocation (first seen, i.e. most recent due to sort order)
        var clusterRepresentative: [GridKey: CLLocation] = [:]
        // Ordered distinct grid keys by recency (most recent first)
        var recentKeys: [GridKey] = []

        result.enumerateObjects { asset, _, _ in
            guard let location = asset.location else { return }
            geotaggedCount += 1
            let key = GridKey(location.coordinate)
            clusterCounts[key, default: 0] += 1
            if clusterRepresentative[key] == nil {
                clusterRepresentative[key] = location
                recentKeys.append(key)
            }
        }

        guard geotaggedCount > 0 else {
            return (0, "", "", [], [])
        }

        let topFrequent = clusterCounts
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map(\.key)

        let recentTop = Array(recentKeys.prefix(10))
        let keysToGeocode = Set(recentTop + topFrequent)

        var names: [GridKey: String] = [:]
        // Reverse geocoding sends coordinates to an Apple service, so it
        // only runs once the user has agreed.
        if CollectionConsent.photosGeocoding.isEnabled {
            let geocoder = CLGeocoder()
            for key in keysToGeocode {
                guard let loc = clusterRepresentative[key] else { continue }
                if let placemark = try? await geocoder.reverseGeocodeLocation(loc).first {
                    names[key] = Self.formatPlacemark(placemark)
                }
            }
        }

        let recentNames = recentTop
            .compactMap { names[$0] }
            .uniqued()
            .prefix(10)
        let recentString = recentNames.joined(separator: ", ")
        let recentEntries = recentNames.map { SignalEntry(label: $0, value: "") }

        let frequentPairs = topFrequent
            .compactMap { key -> (name: String, count: Int)? in
                guard let name = names[key],
                      let count = clusterCounts[key] else { return nil }
                return (name, count)
            }
        let uniqueFrequent = frequentPairs.map { "\($0.name) (\($0.count))" }.uniqued().prefix(10)
        let frequentString = uniqueFrequent.joined(separator: ", ")
        let frequentEntries = frequentPairs
            .map { SignalEntry(label: $0.name, value: String($0.count)) }
            .prefix(10)

        return (geotaggedCount, recentString, frequentString, Array(recentEntries), Array(frequentEntries))
    }

    private static func formatPlacemark(_ placemark: CLPlacemark) -> String {
        let neighborhood = placemark.subLocality
        let city = placemark.locality
        let state = placemark.administrativeArea
        let country = placemark.isoCountryCode

        var components: [String] = []
        if let neighborhood { components.append(neighborhood) }
        if let city, city != neighborhood { components.append(city) }

        if components.isEmpty {
            if let state { components.append(state) }
            if let country { components.append(country) }
        } else if let state {
            components.append(state)
        } else if let country {
            components.append(country)
        }

        return components.isEmpty
            ? String(localized: "Unknown", comment: "Placeholder for an individual location entry on the Photos Recent/Frequent locations cards when reverse-geocoding produced no usable components.")
            : components.joined(separator: ", ")
    }
}

/// Rounds a coordinate to a ~1 km grid cell for clustering nearby photos.
private struct GridKey: Hashable {
    let latBucket: Int
    let lonBucket: Int

    init(_ coordinate: CLLocationCoordinate2D) {
        latBucket = Int((coordinate.latitude * 100).rounded())
        lonBucket = Int((coordinate.longitude * 100).rounded())
    }
}

private extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
