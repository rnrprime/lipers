//
//  SetWallpaperInstructionsView.swift
//  LipersFree
//

import SwiftUI

struct SetWallpaperInstructionsView: View {
    @Environment(\.dismiss) private var dismiss

    private let steps: [(String, String)] = [
        ("1", "Open the Photos app on your iPhone"),
        ("2", "Find the Live Photo you just saved"),
        ("3", "Tap the share button ↑"),
        ("4", "Scroll down and tap \"Use as Wallpaper\""),
        ("5", "Choose Home Screen, Lock Screen, or Both"),
        ("6", "Tap \"Set\" to confirm")
    ]

    var body: some View {
        ZStack {
            AppThemeService.screenBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Set as Wallpaper")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Live Photo saved to your library")
                            .font(.subheadline)
                            .foregroundStyle(AppThemeService.textSecondary)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(AppThemeService.surface, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 32)

                VStack(alignment: .leading, spacing: 22) {
                    ForEach(steps, id: \.0) { step in
                        HStack(alignment: .top, spacing: 16) {
                            Text(step.0)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.black)
                                .frame(width: 26, height: 26)
                                .background(AppThemeService.accent, in: Circle())
                            Text(step.1)
                                .font(.body)
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Spacer()

                Button { dismiss() } label: {
                    Text("Done")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(AppThemeService.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(24)
        }
    }
}

struct SetWallpaperInstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        SetWallpaperInstructionsView()
    }
}
