import WidgetKit
import SwiftUI

// MARK: - API Response Models

struct EthPriceResponse: Codable {
    let priceUSD: Double
    let timestamp: Int64
}

struct GasPriceResponse: Codable {
    let gasPrice: String
    let gasPriceGwei: Double
    let baseFeePerGas: String
    let baseFeePerGasGwei: Double
    let timestamp: Int64
}

// MARK: - API Service

struct BGAPIService {
    static let baseURL = "https://bgethdashboardbackend-production.up.railway.app/api"

    static func fetchEthPrice() async throws -> EthPriceResponse {
        guard let url = URL(string: "\(baseURL)/eth-price") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(EthPriceResponse.self, from: data)
    }

    static func fetchGasPrice() async throws -> GasPriceResponse {
        guard let url = URL(string: "\(baseURL)/gas-price") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(GasPriceResponse.self, from: data)
    }
}

// MARK: - Timeline Entry

struct EthGasEntry: TimelineEntry {
    let date: Date
    let ethPrice: String
    let gasPrice: String
    let gasPriceValue: Double // For the gas indicator bar
}

// MARK: - Timeline Provider

struct EthGasProvider: TimelineProvider {
    // Placeholder for widget gallery
    func placeholder(in context: Context) -> EthGasEntry {
        EthGasEntry(date: Date(), ethPrice: "$3,000", gasPrice: "30 gwei", gasPriceValue: 30)
    }

    // Used for previews and quick glances
    func getSnapshot(in context: Context, completion: @escaping (EthGasEntry) -> ()) {
        if context.isPreview {
            // Return placeholder for preview
            let entry = EthGasEntry(date: Date(), ethPrice: "$3,000", gasPrice: "30 gwei", gasPriceValue: 30)
            completion(entry)
        } else {
            // Fetch real data for snapshot
            Task {
                let entry = await fetchData()
                completion(entry)
            }
        }
    }

    // Main timeline – fetches real data from API
    func getTimeline(in context: Context, completion: @escaping (Timeline<EthGasEntry>) -> ()) {
        Task {
            let entry = await fetchData()

            // Refresh again in 5 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: entry.date)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    // Fetch data from both APIs
    private func fetchData() async -> EthGasEntry {
        let currentDate = Date()

        do {
            async let ethPriceTask = BGAPIService.fetchEthPrice()
            async let gasPriceTask = BGAPIService.fetchGasPrice()

            let (ethResponse, gasResponse) = try await (ethPriceTask, gasPriceTask)

            // Format ETH price with $ and commas
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "$"
            formatter.maximumFractionDigits = 2
            let ethPriceFormatted = formatter.string(from: NSNumber(value: ethResponse.priceUSD)) ?? "$\(ethResponse.priceUSD)"

            // Format gas price - use baseFeePerGasGwei for more accurate display
            let gasPriceGwei = gasResponse.baseFeePerGasGwei
            let gasPriceFormatted: String
            if gasPriceGwei < 1 {
                gasPriceFormatted = String(format: "%.3f gwei", gasPriceGwei)
            } else if gasPriceGwei < 10 {
                gasPriceFormatted = String(format: "%.2f gwei", gasPriceGwei)
            } else {
                gasPriceFormatted = String(format: "%.0f gwei", gasPriceGwei)
            }

            return EthGasEntry(
                date: currentDate,
                ethPrice: ethPriceFormatted,
                gasPrice: gasPriceFormatted,
                gasPriceValue: gasPriceGwei
            )
        } catch {
            // Return fallback data on error
            print("Widget API Error: \(error)")
            return EthGasEntry(
                date: currentDate,
                ethPrice: "—",
                gasPrice: "—",
                gasPriceValue: 0
            )
        }
    }
}

// 3. The widget's UI
struct EthGasWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: EthGasProvider.Entry

    // Calculate gas level (1-5) based on gwei price
    // <1 gwei = 1, 1-10 gwei = 2, 10-30 gwei = 3, 30-100 gwei = 4, >100 gwei = 5
    var gasLevel: Int {
        let gwei = entry.gasPriceValue
        if gwei < 1 { return 1 }
        else if gwei < 10 { return 2 }
        else if gwei < 30 { return 3 }
        else if gwei < 100 { return 4 }
        else { return 5 }
    }

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumWidget
            default:
                smallWidget
            }
        }
        .containerBackground(for: .widget) {
            // Dark gradient matching the app design
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.12),
                    Color(red: 0.08, green: 0.08, blue: 0.18),
                    Color(red: 0.12, green: 0.10, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Small Widget
    var smallWidget: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with BG Logo
            HStack(spacing: 6) {
                Image("BGLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("BG")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // Price
            Text(entry.ethPrice)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // Gas
            HStack(spacing: 4) {
                Image(systemName: "fuelpump.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.cyan.opacity(0.8))
                Text(entry.gasPrice)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            // Timestamp
            Text(entry.date, style: .time)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
    }

    // MARK: - Medium Widget
    var mediumWidget: some View {
        HStack(spacing: 16) {
            // BG Logo on left
            Image("BGLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)

            // Center - ETH Price
            VStack(alignment: .leading, spacing: 4) {
                Text("Ethereum")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))

                Text(entry.ethPrice)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(entry.date, style: .time)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            // Right side - Gas
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "fuelpump.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.cyan)
                    Text("Gas")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Text(entry.gasPrice)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                // Gas indicator bar (based on actual gas price)
                HStack(spacing: 3) {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i < gasLevel ? Color.cyan : Color.white.opacity(0.2))
                            .frame(width: 10, height: 4)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
    }
}

// 4. The widget declaration
struct BGEthGasWidgetExtension: Widget {
    let kind: String = "BGEthGasWidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EthGasProvider()) { entry in
            EthGasWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ETH & Gas")
        .description("Track Ethereum price and gas fees at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// 5. Preview in Xcode canvas
struct BGEthGasWidgetExtension_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EthGasWidgetEntryView(
                entry: EthGasEntry(
                    date: Date(),
                    ethPrice: "$3,128.66",
                    gasPrice: "0.024 gwei",
                    gasPriceValue: 0.024
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small")

            EthGasWidgetEntryView(
                entry: EthGasEntry(
                    date: Date(),
                    ethPrice: "$3,128.66",
                    gasPrice: "0.024 gwei",
                    gasPriceValue: 0.024
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium")
        }
    }
}
