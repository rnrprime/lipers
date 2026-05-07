//
//  WallpaperCardView.swift
//  LipersFree
//

import SwiftUI

struct WallpaperCardView: View {
    let wallpaper: Wallpaper
    var width: CGFloat? = 175
    var height: CGFloat = 270

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: wallpaper.preview_image)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder
                case .empty:
                    placeholder.overlay {
                        ProgressView().tint(AppThemeService.accent)
                    }
                @unknown default:
                    placeholder
                }
            }
            .frame(maxWidth: .infinity)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )

            VStack(alignment: .trailing, spacing: 6) {
                // Live Photo indicator
                Image(systemName: "livephoto")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)

                if wallpaper.is_premium {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(7)
                        .background(AppThemeService.premiumGold, in: Circle())
                }
            }
            .padding(10)
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(AppThemeService.surface)
            .overlay {
                Image(systemName: "photo.on.rectangle")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.25))
            }
    }
}

struct WallpaperCardView_Previews: PreviewProvider {
    static var previews: some View {
        WallpaperCardView(
            wallpaper: Wallpaper(
                id: 1,
                title: "Abstract 1",
                preview_image: "https://picsum.photos/400/700",
                file_url: "https://example.com/video.mp4",
                is_premium: true
            ),
            width: 175,
            height: 270
        )
        .padding()
        .background(AppThemeService.screenBackground)
        .preferredColorScheme(.dark)
    }
}
