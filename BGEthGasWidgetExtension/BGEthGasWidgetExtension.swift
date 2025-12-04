import WidgetKit
import SwiftUI

// 1. What one "snapshot" of data looks like
struct EthGasEntry: TimelineEntry {
    let date: Date
    let ethPrice: String
    let gasPrice: String
}

// 2. How the system gets data over time
struct EthGasProvider: TimelineProvider {
    // Placeholder for widget gallery
    func placeholder(in context: Context) -> EthGasEntry {
        EthGasEntry(date: Date(), ethPrice: "$3,000", gasPrice: "30 gwei")
    }

    // Used for previews
    func getSnapshot(in context: Context, completion: @escaping (EthGasEntry) -> ()) {
        let entry = EthGasEntry(date: Date(), ethPrice: "$3,000", gasPrice: "30 gwei")
        completion(entry)
    }

    // Main timeline – here we will later fetch real data
    func getTimeline(in context: Context, completion: @escaping (Timeline<EthGasEntry>) -> ()) {
        let currentDate = Date()

        // TODO: later replace these with real API values
        let entry = EthGasEntry(
            date: currentDate,
            ethPrice: "$3,000",
            gasPrice: "30 gwei"
        )

        // Refresh again in 10 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// 3. The widget's UI
struct EthGasWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: EthGasProvider.Entry

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

                // Gas indicator bar
                HStack(spacing: 3) {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i < 2 ? Color.cyan : Color.white.opacity(0.2))
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
                    ethPrice: "$3,000",
                    gasPrice: "30 gwei"
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small")

            EthGasWidgetEntryView(
                entry: EthGasEntry(
                    date: Date(),
                    ethPrice: "$3,000",
                    gasPrice: "30 gwei"
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium")
        }
    }
}
