//
//  WallpaperDetailView.swift
//  LipersFree
//

import AVKit
import SwiftUI

private enum WorkState { case idle, downloading, setting }

struct WallpaperDetailView: View {
    let wallpaper: Wallpaper

    @Environment(\.dismiss) private var dismiss
    @State private var currentWallpaper: Wallpaper
    @State private var relatedWallpapers: [Wallpaper] = []
    @State private var player = AVPlayer()
    @State private var workState: WorkState = .idle
    @State private var showInstructions = false
    @State private var toast: Toast?

    init(wallpaper: Wallpaper) {
        self.wallpaper = wallpaper
        self._currentWallpaper = State(initialValue: wallpaper)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VideoPlayerView(player: player)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                dismissButton
                Spacer()
                bottomControls
            }

            if let toast {
                VStack {
                    Spacer()
                    ToastView(toast: toast)
                        .padding(.bottom, 200)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.35), value: toast)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            configureAndPlay()
            Task { await loadRelated() }
        }
        .onDisappear { player.pause() }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { notification in
            guard let current = player.currentItem,
                  let finished = notification.object as? AVPlayerItem,
                  finished == current else { return }
            current.seek(to: .zero) { _ in player.play() }
        }
        .sheet(isPresented: $showInstructions) {
            SetWallpaperInstructionsView()
        }
    }

    // MARK: - Dismiss

    private var dismissButton: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(.black.opacity(0.4), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 32)
        .padding(.horizontal, 20)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 0) {
            actionButtons
                .padding(.top, 28)
                .padding(.bottom, 20)

            thumbnailStrip
                .padding(.bottom, 12)
        }
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 0) {
            Spacer()

            circleButton(
                icon: "square.and.arrow.down.on.square",
                isLoading: workState == .setting,
                diameter: 52
            ) { Task { await setWallpaper() } }

            Spacer()

            circleButton(
                icon: "arrow.down",
                isLoading: workState == .downloading,
                diameter: 68
            ) { Task { await downloadWallpaper() } }

            Spacer()

            circleButton(
                icon: "heart",
                isLoading: false,
                diameter: 52
            ) { }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func circleButton(
        icon: String,
        isLoading: Bool,
        diameter: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.black.opacity(0.35))
                    .frame(width: diameter, height: diameter)
                Circle()
                    .stroke(Color.white.opacity(0.75), lineWidth: 1.5)
                    .frame(width: diameter, height: diameter)

                if isLoading {
                    ProgressView().tint(.white).scaleEffect(0.75)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: diameter * 0.3, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(workState != .idle)
    }

    // MARK: - Thumbnail Strip

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 5) {
                ForEach(relatedWallpapers) { wp in
                    thumbnailCard(wp)
                        .onTapGesture { selectWallpaper(wp) }
                }
            }
            .padding(.horizontal, 14)
        }
        .frame(height: 104)
    }

    private func thumbnailCard(_ wp: Wallpaper) -> some View {
        let isSelected = wp.id == currentWallpaper.id
        return ZStack {
            AsyncImage(url: URL(string: wp.preview_image)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    Rectangle().fill(Color.white.opacity(0.08))
                }
            }
            .frame(width: 64, height: 92)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        isSelected ? Color.white : Color.white.opacity(0.12),
                        lineWidth: isSelected ? 2 : 0.5
                    )
            )

            if isSelected {
                Circle()
                    .fill(Color.black.opacity(0.45))
                    .frame(width: 22, height: 22)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    // MARK: - Logic

    private func selectWallpaper(_ wp: Wallpaper) {
        guard wp.id != currentWallpaper.id else { return }
        currentWallpaper = wp
        configureAndPlay()
    }

    private func downloadWallpaper() async {
        guard let imageURL = currentWallpaper.live_image_url,
              let videoURL = currentWallpaper.live_video_url else {
            showToast("Live wallpaper not available yet", isError: true)
            return
        }
        workState = .downloading
        do {
            try await LivePhotoService.shared.saveToPhotos(imageURLString: imageURL, videoURLString: videoURL)
            showToast("Saved to Photos")
        } catch {
            showToast(error.localizedDescription, isError: true)
        }
        workState = .idle
    }

    private func setWallpaper() async {
        guard let imageURL = currentWallpaper.live_image_url,
              let videoURL = currentWallpaper.live_video_url else {
            showToast("Live wallpaper not available yet", isError: true)
            return
        }
        workState = .setting
        do {
            try await LivePhotoService.shared.saveToPhotos(imageURLString: imageURL, videoURLString: videoURL)
            showInstructions = true
        } catch {
            showToast(error.localizedDescription, isError: true)
        }
        workState = .idle
    }

    private func showToast(_ message: String, isError: Bool = false) {
        withAnimation { toast = Toast(message: message, isError: isError) }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation { toast = nil }
        }
    }

    private func configureAndPlay() {
        guard let url = URL(string: currentWallpaper.file_url) else { return }
        let current = (player.currentItem?.asset as? AVURLAsset)?.url
        guard current != url else { player.play(); return }
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        player.play()
    }

    private func loadRelated() async {
        guard let categoryId = currentWallpaper.category?.id else {
            relatedWallpapers = [currentWallpaper]
            return
        }
        do {
            let response = try await APIService.shared.fetchWallpapers(categoryId: categoryId, page: 1)
            relatedWallpapers = response.data
        } catch {
            relatedWallpapers = [currentWallpaper]
        }
    }
}

struct WallpaperDetailView_Previews: PreviewProvider {
    static var previews: some View {
        WallpaperDetailView(
            wallpaper: Wallpaper(
                id: 1,
                title: "Abstract 1",
                preview_image: "https://picsum.photos/400/700",
                file_url: "https://example.com/video.mp4",
                live_image_url: nil,
                live_video_url: nil,
                is_premium: false,
                category: nil
            )
        )
    }
}
