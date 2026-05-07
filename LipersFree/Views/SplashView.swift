//
//  SplashView.swift
//  LipersFree
//

import SwiftUI

struct SplashView: View {
    let onComplete: () -> Void

    @State private var dotIndex: Int = -1
    @State private var emblemVisible = false
    @State private var ringRotation: Double = 0
    @State private var titleVisible = false
    @State private var slideProgress: Double = 0
    @State private var mingleProgress: Double = 0
    @State private var lipersGlow: Double = 0

    private let dotCount = 8
    private let dotRadius: CGFloat = 96

    var body: some View {
        ZStack {
            AppThemeService.screenBackground.ignoresSafeArea()

            VStack(spacing: 64) {
                centerSection
                titleSection
            }
        }
        .onAppear { runSequence() }
    }

    // MARK: - Center: Live Photo emblem with chase dots

    private var centerSection: some View {
        ZStack {
            chaseDots
            liveEmblem
        }
        .frame(width: 220, height: 220)
    }

    private var chaseDots: some View {
        ForEach(0..<dotCount, id: \.self) { i in
            let angle = Double(i) * (2 * .pi / Double(dotCount)) - .pi / 2
            let isActive = dotIndex == i
            Circle()
                .fill(AppThemeService.accent)
                .frame(width: 7, height: 7)
                .scaleEffect(isActive ? 1.9 : 1.0)
                .opacity(isActive ? 1.0 : 0.18)
                .shadow(color: isActive ? AppThemeService.accentLight : .clear, radius: 14)
                .offset(x: dotRadius * cos(angle), y: dotRadius * sin(angle))
                .animation(.easeInOut(duration: 0.18), value: dotIndex)
        }
    }

    private var liveEmblem: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [AppThemeService.accent, AppThemeService.accentLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [3, 6])
                )
                .frame(width: 84, height: 84)
                .rotationEffect(.degrees(ringRotation))

            Circle()
                .strokeBorder(.white.opacity(0.85), lineWidth: 2.5)
                .frame(width: 56, height: 56)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppThemeService.accent, AppThemeService.accentLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 18, height: 18)
                .shadow(color: AppThemeService.accent.opacity(0.9), radius: 10)
        }
        .scaleEffect(emblemVisible ? 1.0 : 0.85)
        .opacity(emblemVisible ? 1.0 : 0.0)
    }

    // MARK: - Title

    private var titleSection: some View {
        LetterMingleTitle(
            slideProgress: slideProgress,
            mingleProgress: mingleProgress,
            glow: lipersGlow
        )
        .frame(height: 50)
        .opacity(titleVisible ? 1 : 0)
    }

    // MARK: - Choreography

    private func runSequence() {
        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.45)) { emblemVisible = true }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }

            try? await Task.sleep(for: .milliseconds(220))

            // Phase 1: chase dots — 12 steps (1.5 cycles)
            for step in 0..<12 {
                dotIndex = step % dotCount
                try? await Task.sleep(for: .milliseconds(70))
            }
            dotIndex = -1

            try? await Task.sleep(for: .milliseconds(150))

            // Phase 2: words slide in from opposite sides (smooth, no spring)
            withAnimation(.easeOut(duration: 0.35)) { titleVisible = true }
            withAnimation(.easeInOut(duration: 0.7)) { slideProgress = 1.0 }

            try? await Task.sleep(for: .milliseconds(900))

            // Phase 3: letters mingle into "Lipers"
            withAnimation(.easeInOut(duration: 0.85)) { mingleProgress = 1.0 }

            try? await Task.sleep(for: .milliseconds(700))

            // Phase 4: subtle glow on the final word, then complete
            withAnimation(.easeInOut(duration: 0.4)) { lipersGlow = 1.0 }

            try? await Task.sleep(for: .milliseconds(700))
            onComplete()
        }
    }
}

// MARK: - Letter mingle title

private struct LetterMingleTitle: View {
    let slideProgress: Double
    let mingleProgress: Double
    let glow: Double

    private let phrase = "Live Wallpapers"
    /// Indices that survive into "Lipers": L(0) i(1) p(9) e(12) r(13) s(14)
    private let keepIndices: [Int] = [0, 1, 9, 12, 13, 14]
    private let letterWidth: CGFloat = 17
    private let slideDistance: CGFloat = 220

    private var chars: [Character] { Array(phrase) }

    var body: some View {
        ZStack {
            ForEach(0..<chars.count, id: \.self) { i in
                letterAt(i)
            }
        }
    }

    @ViewBuilder
    private func letterAt(_ i: Int) -> some View {
        let isKeeper = keepIndices.contains(i)
        Text(String(chars[i]))
            .font(.system(size: 26, weight: .semibold, design: .rounded).monospaced())
            .foregroundStyle(.white)
            .tracking(0.5)
            .opacity(isKeeper ? 1.0 : 1.0 - mingleProgress)
            .shadow(color: AppThemeService.accent.opacity(isKeeper ? glow * 0.7 : 0),
                    radius: 12)
            .offset(x: xOffset(for: i))
    }

    private func xOffset(for i: Int) -> CGFloat {
        let mid = CGFloat(chars.count - 1) / 2
        let compactMid = CGFloat(keepIndices.count - 1) / 2
        let naturalX = (CGFloat(i) - mid) * letterWidth

        let targetX: CGFloat
        if let keeperIdx = keepIndices.firstIndex(of: i) {
            targetX = (CGFloat(keeperIdx) - compactMid) * letterWidth
        } else {
            targetX = naturalX
        }

        let mingledX = naturalX + (targetX - naturalX) * mingleProgress
        let slideOffset = (i <= 4 ? -slideDistance : slideDistance) * (1 - slideProgress)
        return mingledX + slideOffset
    }
}

#Preview {
    SplashView(onComplete: {})
}
