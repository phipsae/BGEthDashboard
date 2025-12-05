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

            VStack(spacing: 0) {
                Spacer()

                // Logo
                Image("BGLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .shadow(color: .purple.opacity(0.4), radius: 40, x: 0, y: 15)

                Spacer()
                    .frame(height: 40)

                // Title
                VStack(spacing: 8) {
                    Text("BG Eth Tracker")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .opacity(textOpacity)

                Spacer()
                    .frame(height: 50)

                // Instructions card
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.square.on.square")
                            .font(.system(size: 24))
                            .foregroundStyle(.cyan)

                        Text("Add the Widget")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Divider()
                        .background(.white.opacity(0.1))

                    VStack(alignment: .leading, spacing: 16) {
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
                            text: "Search for \"Eth Tracker\""
                        )

                        InstructionRow(
                            step: "4",
                            icon: "checkmark.circle.fill",
                            text: "Choose a size and tap Add Widget"
                        )
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

                // Footer
                Text("Track ETH price & gas fees at a glance")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                    .opacity(instructionsOpacity)
                    .padding(.bottom, 30)
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
