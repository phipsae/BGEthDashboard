import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Refresh Intent

struct RefreshWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Widget"
    static var description = IntentDescription("Refreshes the ETH Tracker widget data")

    func perform() async throws -> some IntentResult {
        // Brief delay to let XPC connection stabilize
        try? await Task.sleep(for: .milliseconds(50))
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// Force the intent to run in the main app process to avoid widget extension XPC issues
// Note: ForegroundContinuableIntent is only available on iOS, not macOS
#if os(iOS)
@available(iOSApplicationExtension, unavailable)
extension RefreshWidgetIntent: ForegroundContinuableIntent {}
#endif

// MARK: - Timeline Entry

struct DashboardEntry: TimelineEntry {
    let date: Date
    let data: DashboardResponse?   // nil only on first run with no network
    let lastUpdated: Date?
    let isStale: Bool
}

// MARK: - Local cache of the last successful fetch

struct CachedDashboard: Codable {
    let data: DashboardResponse
    let fetchedAt: Date
}

enum DashboardCache {
    private static let key = "cachedDashboard"

    static func save(_ data: DashboardResponse) {
        let cached = CachedDashboard(data: data, fetchedAt: Date())
        if let encoded = try? JSONEncoder().encode(cached) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    static func load() -> CachedDashboard? {
        guard let encoded = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(CachedDashboard.self, from: encoded)
    }
}

// MARK: - Timeline Provider

struct DashboardProvider: TimelineProvider {
    func placeholder(in context: Context) -> DashboardEntry {
        DashboardEntry(date: Date(), data: .sample, lastUpdated: Date(), isStale: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (DashboardEntry) -> ()) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            Task { completion(await fetchEntry().entry) }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DashboardEntry>) -> ()) {
        Task {
            let (entry, retrySooner) = await fetchEntry()
            let minutes = retrySooner ? 2 : 5
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: minutes, to: entry.date)!
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    /// Fetches fresh data; on failure falls back to the last cached payload.
    private func fetchEntry() async -> (entry: DashboardEntry, retrySooner: Bool) {
        let now = Date()
        do {
            let data = try await DashboardAPIService.fetchDashboard()
            DashboardCache.save(data)
            return (DashboardEntry(date: now, data: data, lastUpdated: now, isStale: false), false)
        } catch {
            print("Widget API Error: \(error)")
            if let cached = DashboardCache.load() {
                let entry = DashboardEntry(
                    date: now,
                    data: cached.data,
                    lastUpdated: cached.fetchedAt,
                    isStale: true
                )
                return (entry, true)
            }
            return (DashboardEntry(date: now, data: nil, lastUpdated: nil, isStale: false), true)
        }
    }
}

// MARK: - Widget declaration

struct BGEthDashboardWidgetExtension: Widget {
    let kind: String = "BGEthDashboardWidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DashboardProvider()) { entry in
            EthGasWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ETH Tracker")
        .description("Ethereum price, gas, staking and DeFi stats at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
