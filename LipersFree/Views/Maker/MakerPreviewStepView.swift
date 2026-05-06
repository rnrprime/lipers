//
//  MakerPreviewStepView.swift
//  LipersFree
//

import AVKit
import SwiftUI

struct MakerPreviewStepView: View {
    var vm: MakerViewModel
    let videoURL: URL
    let frameTime: CMTime
    let still: UIImage
    let ratio: AspectRatio

    @State private var player = AVPlayer()
    @State private var duration: Double = 0
    @State private var trimStart: Double = 0
    @State private var trimEnd: Double = 0
    @State private var isReady = false

    var body: some View {
        VStack(spacing: 0) {
            header

            videoPreview
                .layoutPriority(1)

            trimSection
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

            actionRow
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task { await setup() }
        .onDisappear { player.pause() }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
            loopFromTrimStart()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Trim & Preview")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text("Drag the handles to set video length")
                .font(.subheadline)
                .foregroundStyle(AppThemeService.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Video preview

    private var videoPreview: some View {
        ZStack {
            Color.black

            if isReady {
                VideoPlayerView(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView().tint(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Trim section

    private var trimSection: some View {
        VStack(spacing: 10) {
            VideoTrimmerView(
                videoURL: videoURL,
                duration: duration,
                trimStart: $trimStart,
                trimEnd: $trimEnd,
                onTrimEnd: { applyTrim() }
            )
            .onChange(of: trimEnd) { _, newEnd in
                player.currentItem?.forwardPlaybackEndTime = CMTime(seconds: newEnd, preferredTimescale: 600)
            }

            // Time info
            HStack {
                Text(formatted(trimStart))
                Spacer()
                Text(formatted(trimEnd - trimStart) + " selected")
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                Spacer()
                Text(formatted(trimEnd))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(AppThemeService.textSecondary)
        }
        .padding(14)
        .background(AppThemeService.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button("Back") { vm.goBack() }
                .buttonStyle(SecondaryButtonStyle())

            Button {
                Task {
                    await vm.save(
                        videoURL: videoURL,
                        frameTime: frameTime,
                        ratio: ratio,
                        trimStart: trimStart,
                        trimEnd: trimEnd
                    )
                }
            } label: {
                if vm.isSaving {
                    HStack(spacing: 8) {
                        ProgressView().tint(.white).scaleEffect(0.85)
                        Text("Saving…")
                    }
                } else {
                    Label("Save to Photos", systemImage: "square.and.arrow.down")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(vm.isSaving)
        }
    }

    // MARK: - Logic

    private func setup() async {
        let asset = AVURLAsset(url: videoURL)
        guard let dur = try? await asset.load(.duration) else { return }
        duration  = CMTimeGetSeconds(dur)
        trimStart = 0
        trimEnd   = min(duration, 10) // cap initial selection at 10 s

        let item = AVPlayerItem(url: videoURL)
        item.forwardPlaybackEndTime = CMTime(seconds: trimEnd, preferredTimescale: 600)
        player.replaceCurrentItem(with: item)
        player.seek(to: .zero) { _ in self.player.play() }
        isReady = true
    }

    private func applyTrim() {
        // Called when user releases a handle — seek to new start and resume
        player.currentItem?.forwardPlaybackEndTime = CMTime(seconds: trimEnd, preferredTimescale: 600)
        player.seek(to: CMTime(seconds: trimStart, preferredTimescale: 600)) { _ in
            self.player.play()
        }
    }

    private func loopFromTrimStart() {
        player.seek(to: CMTime(seconds: trimStart, preferredTimescale: 600)) { _ in
            self.player.play()
        }
    }

    private func formatted(_ t: Double) -> String {
        let s = Int(t)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
