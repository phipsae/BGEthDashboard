//
//  DashboardCache.swift
//  Shared between BGEthDashboard app and widget extension
//
//  Backed by an App Group so the app and the widget read/write the same last-good
//  payload. The app writes fresh data here on every refresh; the widget serves it as a
//  fallback whenever its own fetch fails, so the widget never has to show an empty entry.
//

import Foundation

enum AppGroup {
    static let id = "group.phipsae.BGEthDashboard"

    /// App Group defaults, falling back to `.standard` if the suite is unavailable
    /// (e.g. a misconfigured entitlement) so callers never crash.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: id) ?? .standard
    }
}

struct CachedDashboard: Codable {
    let data: DashboardResponse
    let fetchedAt: Date
}

enum DashboardCache {
    private static let key = "cachedDashboard"

    static func save(_ data: DashboardResponse) {
        let cached = CachedDashboard(data: data, fetchedAt: Date())
        if let encoded = try? JSONEncoder().encode(cached) {
            AppGroup.defaults.set(encoded, forKey: key)
        }
    }

    static func load() -> CachedDashboard? {
        guard let encoded = AppGroup.defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(CachedDashboard.self, from: encoded)
    }
}
