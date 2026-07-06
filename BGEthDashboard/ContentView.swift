//
//  ContentView.swift
//  BGEthGasWidget
//
//  Created by Philip on 04.12.25.
//

import SwiftUI

struct ContentView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var instructionsOpacity: Double = 0
    @State private var instructionsExpanded = false
    @State private var refreshID = UUID()

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.12),
                    Color(red: 0.08, green: 0.08, blue: 0.18),
                    Color(red: 0.12, green: 0.10, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle pattern overlay
            GeometryReader { geo in
                Canvas { context, size in
                    for i in stride(from: 0, to: size.width, by: 40) {
                        for j in stride(from: 0, to: size.height, by: 40) {
                            let rect = CGRect(x: i, y: j, width: 1, height: 1)
                            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.03)))
                        }
                    }
                }
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                // Logo + title header
                HStack(spacing: 12) {
                    Image("BGLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .shadow(color: .purple.opacity(0.4), radius: 12, x: 0, y: 4)

                    Text("ETH Tracker")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(textOpacity)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()
                    .frame(height: 20)

                // Live dashboard
                DashboardView()
                    .id(refreshID)
                    .opacity(textOpacity)
                    .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 24)

                // Instructions card (tap the header to collapse/expand)
                VStack(spacing: 20) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            instructionsExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.square.on.square")
                                .font(.system(size: 24))
                                .foregroundStyle(.cyan)

                            Text("Add the Widget")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .rotationEffect(.degrees(instructionsExpanded ? 0 : -90))
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(instructionsExpanded ? "Hide widget instructions" : "Show widget instructions")

                    if instructionsExpanded {
                    Divider()
                        .background(.white.opacity(0.1))

                    VStack(alignment: .leading, spacing: 16) {
                        #if os(macOS)
                        InstructionRow(
                            step: "1",
                            icon: "hand.tap",
                            text: "Right-click your desktop and choose Edit Widgets"
                        )

                        InstructionRow(
                            step: "2",
                            icon: "magnifyingglass",
                            text: "Search for \"ETH Tracker\""
                        )

                        InstructionRow(
                            step: "3",
                            icon: "checkmark.circle.fill",
                            text: "Choose a size and click + to add it"
                        )
                        #else
                        InstructionRow(
                            step: "1",
                            icon: "hand.tap",
                            text: "Long press on your Home Screen"
                        )

                        InstructionRow(
                            step: "2",
                            icon: "plus.circle",
                            text: "Tap the + button in the top corner"
                        )

                        InstructionRow(
                            step: "3",
                            icon: "magnifyingglass",
                            text: "Search for \"ETH Tracker\""
                        )

                        InstructionRow(
                            step: "4",
                            icon: "checkmark.circle.fill",
                            text: "Choose a size and tap Add Widget"
                        )
                        #endif
                    }
                    }
                }
                .padding(24)
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
                .opacity(instructionsOpacity)
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 24)

                // Footer
                Text("Track ETH price & gas fees at a glance")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                    .opacity(instructionsOpacity)
                    .padding(.bottom, 30)
                }
            }
            .refreshable {
                refreshID = UUID()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                textOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                instructionsOpacity = 1.0
            }
        }
    }
}

struct InstructionRow: View {
    let step: String
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)

                Text(step)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.cyan.opacity(0.8))
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))

            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
