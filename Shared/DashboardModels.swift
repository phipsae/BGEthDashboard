//
//  DashboardModels.swift
//  Shared between BGEthDashboard app and widget extension
//

import Foundation

/// Response of GET /api/dashboard. Sections are nil when their upstream
/// failed on the backend, so every consumer must degrade per-section.
struct DashboardResponse: Codable {
    struct Price: Codable {
        let usd: Double
        let change24hPct: Double?
        let sparkline: [Double]?
    }

    struct Gas: Codable {
        let gasPriceGwei: Double
        let baseFeePerGasGwei: Double?
        let priorityFeeGwei: Double?
    }

    struct Staking: Codable {
        let totalStakedEth: Double
        let stakedPercent: Double
        let aprPercent: Double
    }

    struct Tvl: Codable {
        let tvlUsd: Double
        let change24hPct: Double
    }

    let price: Price?
    let gas: Gas?
    let staking: Staking?
    let tvl: Tvl?
    let timestamp: Int64
}

extension DashboardResponse.Gas {
    /// Displayed gas value, base fee preferred over legacy gas price.
    var displayGwei: Double { baseFeePerGasGwei ?? gasPriceGwei }

    /// Congestion level 1-5.
    /// <0.5 ultra-low, <3 typical, <15 busy, <60 high, else spike.
    var level: Int {
        let gwei = displayGwei
        if gwei < 0.5 { return 1 }
        else if gwei < 3 { return 2 }
        else if gwei < 15 { return 3 }
        else if gwei < 60 { return 4 }
        else { return 5 }
    }
}

// MARK: - Shared formatting

enum DashboardFormat {
    private static let usLocale = Locale(identifier: "en_US")

    static func price(_ usd: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = usLocale
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: usd)) ?? "$\(Int(usd))"
    }

    static func gwei(_ value: Double) -> String {
        if value < 1 { return String(format: "%.3f", value) }
        else if value < 10 { return String(format: "%.2f", value) }
        else { return String(format: "%.0f", value) }
    }

    static func changePct(_ pct: Double) -> String {
        String(format: "%@%.1f%%", pct >= 0 ? "+" : "", pct)
    }

    /// Compact notation, e.g. 40_543_733 -> "40.5M"
    static func compact(_ value: Double) -> String {
        value.formatted(
            .number.notation(.compactName)
                .precision(.significantDigits(3))
                .locale(usLocale)
        )
    }

    /// Compact USD, e.g. 39_596_338_119 -> "$39.6B"
    static func compactUsd(_ value: Double) -> String {
        "$" + compact(value)
    }
}

// MARK: - Sample data (placeholders / previews)

extension DashboardResponse {
    static let sample = DashboardResponse(
        price: Price(
            usd: 3129,
            change24hPct: 2.3,
            sparkline: [3050, 3062, 3048, 3071, 3080, 3075, 3090, 3102, 3095, 3110,
                        3118, 3105, 3112, 3125, 3119, 3130, 3122, 3135, 3128, 3140,
                        3133, 3127, 3135, 3131, 3129]
        ),
        gas: Gas(gasPriceGwei: 0.85, baseFeePerGasGwei: 0.72, priorityFeeGwei: 1.5),
        staking: Staking(totalStakedEth: 40_543_733, stakedPercent: 33.3, aprPercent: 2.56),
        tvl: Tvl(tvlUsd: 39_596_338_119, change24hPct: 1.89),
        timestamp: Int64(Date().timeIntervalSince1970 * 1000)
    )
}
