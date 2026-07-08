//
//  DashboardAPIService.swift
//  Shared between BGEthDashboard app and widget extension
//

import Foundation

struct DashboardAPIService {
    static let baseURL = "https://bgethdashboardbackend-production.up.railway.app/api"

    /// Shared session for the app (uses the system default timeouts).
    static func fetchDashboard() async throws -> DashboardResponse {
        try await fetchDashboard(using: .shared)
    }

    /// Session with a short request timeout, for use inside the widget extension.
    ///
    /// WidgetKit only gives a `TimelineProvider` a few seconds to call its completion
    /// handler. `URLSession.shared` defaults to a 60s request timeout, so a slow or
    /// unreachable server can get the extension killed before it delivers an entry,
    /// leaving the widget stuck on the redacted placeholder. This session fails fast so
    /// the provider can always fall back to cached data and complete in time.
    static let widgetSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 12
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    static func fetchDashboard(using session: URLSession) async throws -> DashboardResponse {
        guard let url = URL(string: "\(baseURL)/dashboard") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(DashboardResponse.self, from: data)
    }
}
