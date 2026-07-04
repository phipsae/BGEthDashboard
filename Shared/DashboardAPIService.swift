//
//  DashboardAPIService.swift
//  Shared between BGEthDashboard app and widget extension
//

import Foundation

struct DashboardAPIService {
    static let baseURL = "https://bgethdashboardbackend-production.up.railway.app/api"

    static func fetchDashboard() async throws -> DashboardResponse {
        guard let url = URL(string: "\(baseURL)/dashboard") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(DashboardResponse.self, from: data)
    }
}
