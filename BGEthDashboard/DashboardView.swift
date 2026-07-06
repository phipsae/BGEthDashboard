//
//  DashboardView.swift
//  BGEthDashboard
//

import SwiftUI
import Charts

struct DashboardView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var data: DashboardResponse?
    @State private var failedToLoad = false

    private let refreshInterval: TimeInterval = 60

    var body: some View {
        VStack(spacing: 16) {
            // Price header
            VStack(spacing: 4) {
                Text("Ethereum")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))

                Text(data?.price.map { DashboardFormat.price($0.usd) } ?? "—")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                if let pct = data?.price?.change24hPct {
                    HStack(spacing: 3) {
                        Image(systemName: pct >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 13, weight: .bold))
                        Text(DashboardFormat.changePct(pct))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(pct >= 0 ? .green : .red)
                }
            }
            .accessibilityElement(children: .combine)

            // Sparkline
            if let sparkline = data?.price?.sparkline, sparkline.count >= 2,
               let min = sparkline.min(), let max = sparkline.max() {
                let tint: Color = (data?.price?.change24hPct ?? 0) >= 0 ? .green : .red
                Chart(Array(sparkline.enumerated()), id: \.offset) { index, value in
                    LineMark(x: .value("Hour", index), y: .value("Price", value))
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                        .foregroundStyle(tint)
                        .interpolationMethod(.catmullRom)
                    AreaMark(x: .value("Hour", index), y: .value("Price", value))
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
                .frame(height: 70)
                .clipped()
                .accessibilityLabel("24 hour price chart")
            }

            // Stat grid: cells are left-aligned, the grid as a whole is centered
            Grid(alignment: .leading, horizontalSpacing: 48, verticalSpacing: 12) {
                GridRow {
                    AppStatCell(
                        title: "Gas",
                        value: data?.gas.map { "\(DashboardFormat.gwei($0.displayGwei)) gwei" } ?? "—",
                        icon: "fuelpump.fill"
                    )
                    AppStatCell(
                        title: "Staked ETH",
                        value: data?.staking.map { DashboardFormat.compact($0.totalStakedEth) } ?? "—",
                        icon: "lock.fill"
                    )
                }
                GridRow {
                    AppStatCell(
                        title: "% of Supply Staked",
                        value: data?.staking.map { String(format: "%.1f%%", $0.stakedPercent) } ?? "—",
                        icon: "chart.pie.fill"
                    )
                    AppStatCell(
                        title: "Staking APR",
                        value: data?.staking.map { String(format: "%.2f%%", $0.aprPercent) } ?? "—",
                        icon: "percent"
                    )
                }
                GridRow {
                    AppStatCell(
                        title: "DeFi TVL",
                        value: data?.tvl.map { DashboardFormat.compactUsd($0.tvlUsd) } ?? "—",
                        icon: "building.columns.fill"
                    )
                    AppStatCell(
                        title: "TVL 24h",
                        value: data?.tvl.map { DashboardFormat.changePct($0.change24hPct) } ?? "—",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
            }

            if failedToLoad {
                Text(data == nil ? "Couldn't load data. Pull to retry." : "Showing last loaded data. Pull to retry.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.orange.opacity(0.8))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .overlay(alignment: .topTrailing) {
            Button {
                Task { await load() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(14)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Refresh")
        }
        .task {
            await load()
            // Periodic refresh while the dashboard stays on screen
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(refreshInterval))
                await load()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await load() }
            }
        }
    }

    func load() async {
        do {
            let fresh = try await DashboardAPIService.fetchDashboard()
            withAnimation { data = fresh }
            failedToLoad = false
        } catch {
            failedToLoad = true
        }
    }
}

struct AppStatCell: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(.cyan.opacity(0.8))
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) \(value)")
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        DashboardView()
    }
}
