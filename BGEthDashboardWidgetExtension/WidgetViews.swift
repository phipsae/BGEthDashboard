import WidgetKit
import SwiftUI
import Charts
import AppIntents

// MARK: - Entry view (family switch)

struct EthGasWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: DashboardProvider.Entry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        .containerBackground(for: .widget) {
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
}

// MARK: - Shared pieces

private struct CornerLogo: View {
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Image("BGLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .accessibilityHidden(true)
            }
            Spacer()
        }
        .padding(.top, -10)
        .padding(.trailing, -10)
    }
}

private struct RefreshButton: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(intent: RefreshWidgetIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Refresh")
            }
        }
    }
}

/// Timestamp line, orange warning variant when data is stale.
struct UpdatedFooter: View {
    let entry: DashboardEntry

    var body: some View {
        if entry.isStale, let lastUpdated = entry.lastUpdated {
            HStack(spacing: 3) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 8))
                Text(lastUpdated, style: .relative)
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(.orange.opacity(0.8))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Data last updated \(lastUpdated.formatted(.relative(presentation: .named)))")
        } else {
            Text(entry.date, style: .time)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

/// Colored 24h change, e.g. "↗ +2.3%".
struct ChangeBadge: View {
    let pct: Double
    var fontSize: CGFloat = 12

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: pct >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: fontSize - 2, weight: .bold))
            Text(DashboardFormat.changePct(pct))
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(pct >= 0 ? .green : .red)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(pct >= 0 ? "up" : "down") \(abs(pct), specifier: "%.1f") percent in 24 hours")
    }
}

struct SparklineView: View {
    let points: [Double]
    let tint: Color

    var body: some View {
        if points.count >= 2, let min = points.min(), let max = points.max() {
            Chart(Array(points.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Hour", index),
                    y: .value("Price", value)
                )
                .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .foregroundStyle(tint)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Hour", index),
                    y: .value("Price", value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [tint.opacity(0.25), tint.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: (min * 0.999)...(max * 1.001))
            .clipped()
            .accessibilityLabel("24 hour price chart")
        }
    }
}

struct StatCell: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(.cyan.opacity(0.8))
                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) \(value)")
    }
}

private struct GasLevelBar: View {
    let level: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < level ? Color.cyan : Color.white.opacity(0.2))
                    .frame(width: 8, height: 4)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Small

struct SmallWidgetView: View {
    let entry: DashboardEntry

    var body: some View {
        ZStack {
            CornerLogo()

            VStack(alignment: .leading, spacing: 4) {
                Spacer()

                Text("Ethereum")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))

                Text(entry.data?.price.map { DashboardFormat.price($0.usd) } ?? "—")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let pct = entry.data?.price?.change24hPct {
                    ChangeBadge(pct: pct, fontSize: 11)
                }

                HStack(spacing: 4) {
                    Image(systemName: "fuelpump.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.cyan.opacity(0.8))
                    Text("\(entry.data?.gas.map { DashboardFormat.gwei($0.displayGwei) } ?? "—") gwei")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(gasAccessibilityLabel(entry.data?.gas))

                Spacer()

                UpdatedFooter(entry: entry)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RefreshButton()
        }
        .padding(12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(priceAccessibilityLabel(entry.data?.price))
    }
}

// MARK: - Medium

struct MediumWidgetView: View {
    let entry: DashboardEntry

    var body: some View {
        ZStack {
            CornerLogo()

            HStack(alignment: .center, spacing: 0) {
                // Price + change + sparkline
                VStack(alignment: .center, spacing: 2) {
                    Text("Ethereum")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))

                    Text(entry.data?.price.map { DashboardFormat.price($0.usd) } ?? "—")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let pct = entry.data?.price?.change24hPct {
                        ChangeBadge(pct: pct, fontSize: 11)
                    }

                    if let sparkline = entry.data?.price?.sparkline {
                        SparklineView(
                            points: sparkline,
                            tint: (entry.data?.price?.change24hPct ?? 0) >= 0 ? .green : .red
                        )
                        .frame(width: 90, height: 26)
                        .padding(.top, 2)
                    }

                    UpdatedFooter(entry: entry)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(priceAccessibilityLabel(entry.data?.price))

                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 1)
                    .frame(maxHeight: 60)

                // Gas
                VStack(alignment: .center, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "fuelpump.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.cyan)
                        Text("Gas")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Text(entry.data?.gas.map { DashboardFormat.gwei($0.displayGwei) } ?? "—")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("gwei")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))

                    GasLevelBar(level: entry.data?.gas?.level ?? 0)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(gasAccessibilityLabel(entry.data?.gas))
            }

            RefreshButton()
        }
        .padding(12)
    }
}

// MARK: - Large

struct LargeWidgetView: View {
    let entry: DashboardEntry

    var body: some View {
        ZStack {
            CornerLogo()

            VStack(alignment: .leading, spacing: 10) {
                // Top: price + change + sparkline
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ethereum")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))

                        Text(entry.data?.price.map { DashboardFormat.price($0.usd) } ?? "—")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        if let pct = entry.data?.price?.change24hPct {
                            ChangeBadge(pct: pct, fontSize: 13)
                        }
                    }
                    Spacer()
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(priceAccessibilityLabel(entry.data?.price))

                if let sparkline = entry.data?.price?.sparkline {
                    SparklineView(
                        points: sparkline,
                        tint: (entry.data?.price?.change24hPct ?? 0) >= 0 ? .green : .red
                    )
                    .frame(height: 50)
                }

                Divider()
                    .background(.white.opacity(0.15))

                // Stat grid: two full-width columns aligned with the divider above
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        StatCell(
                            title: "Gas",
                            value: entry.data?.gas.map { "\(DashboardFormat.gwei($0.displayGwei)) gwei" } ?? "—",
                            icon: "fuelpump.fill"
                        )
                        StatCell(
                            title: "Staked ETH",
                            value: entry.data?.staking.map { DashboardFormat.compact($0.totalStakedEth) } ?? "—",
                            icon: "lock.fill"
                        )
                    }
                    GridRow {
                        StatCell(
                            title: "% of Supply Staked",
                            value: entry.data?.staking.map { String(format: "%.1f%%", $0.stakedPercent) } ?? "—",
                            icon: "chart.pie.fill"
                        )
                        StatCell(
                            title: "Staking APR",
                            value: entry.data?.staking.map { String(format: "%.2f%%", $0.aprPercent) } ?? "—",
                            icon: "percent"
                        )
                    }
                    GridRow {
                        StatCell(
                            title: "DeFi TVL",
                            value: entry.data?.tvl.map { DashboardFormat.compactUsd($0.tvlUsd) } ?? "—",
                            icon: "building.columns.fill"
                        )
                        StatCell(
                            title: "TVL 24h",
                            value: entry.data?.tvl.map { DashboardFormat.changePct($0.change24hPct) } ?? "—",
                            icon: "chart.line.uptrend.xyaxis"
                        )
                    }
                }

                Spacer(minLength: 0)

                UpdatedFooter(entry: entry)
            }

            RefreshButton()
        }
        .padding(14)
    }
}

// MARK: - Accessibility helpers

private func priceAccessibilityLabel(_ price: DashboardResponse.Price?) -> String {
    guard let price else { return "Ethereum price unavailable" }
    var label = "Ethereum price \(Int(price.usd)) dollars"
    if let pct = price.change24hPct {
        label += ", \(pct >= 0 ? "up" : "down") \(String(format: "%.1f", abs(pct))) percent in 24 hours"
    }
    return label
}

private func gasAccessibilityLabel(_ gas: DashboardResponse.Gas?) -> String {
    guard let gas else { return "Gas price unavailable" }
    return "Gas \(DashboardFormat.gwei(gas.displayGwei)) gwei, level \(gas.level) of 5"
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    BGEthDashboardWidgetExtension()
} timeline: {
    DashboardEntry(date: .now, data: .sample, lastUpdated: .now, isStale: false)
}

#Preview("Medium", as: .systemMedium) {
    BGEthDashboardWidgetExtension()
} timeline: {
    DashboardEntry(date: .now, data: .sample, lastUpdated: .now, isStale: false)
}

#Preview("Large", as: .systemLarge) {
    BGEthDashboardWidgetExtension()
} timeline: {
    DashboardEntry(date: .now, data: .sample, lastUpdated: .now, isStale: false)
}

#Preview("Stale", as: .systemMedium) {
    BGEthDashboardWidgetExtension()
} timeline: {
    DashboardEntry(
        date: .now,
        data: .sample,
        lastUpdated: .now.addingTimeInterval(-45 * 60),
        isStale: true
    )
}
