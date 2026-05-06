//
//  ExploreSectionView.swift
//  LipersFree
//

import SwiftUI

struct ExploreSectionView: View {
    let title: String
    let wallpapers: [Wallpaper]
    let onSeeAll: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Spacer()

                Button(action: { onSeeAll?() }) {
                    HStack(spacing: 3) {
                        Text("See All")
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(AppThemeService.accent)
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(wallpapers) { wallpaper in
                        WallpaperCardView(wallpaper: wallpaper)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

struct ExploreSectionView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreSectionView(
            title: "Abstract",
            wallpapers: [
                Wallpaper(
                    id: 1,
                    title: "Abstract 1",
                    preview_image: "https://picsum.photos/400/700",
                    file_url: "https://example.com/video.mp4",
                    live_image_url: "https://example.com/live.jpg",
                    live_video_url: "https://example.com/live.mov",
                    is_premium: false,
                    category: nil
                ),
                Wallpaper(
                    id: 2,
                    title: "Abstract 2",
                    preview_image: "https://picsum.photos/401/700",
                    file_url: "https://example.com/video-2.mp4",
                    live_image_url: "https://example.com/live2.jpg",
                    live_video_url: "https://example.com/live2.mov",
                    is_premium: true,
                    category: nil
                )
            ],
            onSeeAll: nil
        )
        .padding()
        .background(AppThemeService.screenBackground)
        .preferredColorScheme(.dark)
    }
}
