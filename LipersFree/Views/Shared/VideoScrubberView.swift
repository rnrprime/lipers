//
//  VideoScrubberView.swift
//  LipersFree
//

import SwiftUI

struct VideoScrubberView: View {
    let duration: Double
    @Binding var currentTime: Double

    var body: some View {
        VStack(spacing: 6) {
            Slider(value: $currentTime, in: 0...max(duration, 0.001))
                .tint(AppThemeService.accent)

            HStack {
                Text(formatted(0))
                Spacer()
                Text(formatted(currentTime))
                    .foregroundStyle(AppThemeService.textPrimary)
                    .fontWeight(.semibold)
                Spacer()
                Text(formatted(duration))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(AppThemeService.textSecondary)
        }
    }

    private func formatted(_ t: Double) -> String {
        let s = Int(t)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
