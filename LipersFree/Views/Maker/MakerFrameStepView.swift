//
//  MakerFrameStepView.swift
//  LipersFree
//

import AVFoundation
import SwiftUI

struct MakerFrameStepView: View {
    var vm: MakerViewModel
    let videoURL: URL

    private let generator: AVAssetImageGenerator

    @State private var duration: Double = 1
    @State private var currentTime: Double = 0
    @State private var frameImage: UIImage?
    @State private var extractTask: Task<Void, Never>?
    @State private var selectedRatio: AspectRatio = .portrait

    init(vm: MakerViewModel, videoURL: URL) {
        self.vm = vm
        self.videoURL = videoURL
        let gen = AVAssetImageGenerator(asset: AVURLAsset(url: videoURL))
        gen.appliesPreferredTrackTransform = true
        gen.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        gen.requestedTimeToleranceAfter  = CMTime(seconds: 0.1, preferredTimescale: 600)
        self.generator = gen
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ratioPicker
                .padding(.horizontal, 20)
                .padding(.top, 14)
            framePreview
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .layoutPriority(1)
            scrubberSection
                .padding(.horizontal, 20)
                .padding(.top, 12)
            actionRow
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task { await loadVideo() }
        .onChange(of: currentTime) { _, newTime in scheduleExtract(at: newTime) }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Choose Still Frame")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text("Pick your key frame and output ratio")
                .font(.subheadline)
                .foregroundStyle(AppThemeService.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Ratio picker

    private var ratioPicker: some View {
        HStack(spacing: 8) {
            ForEach(AspectRatio.allCases) { ratio in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedRatio = ratio }
                } label: {
                    Text(ratio.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selectedRatio == ratio ? .white : AppThemeService.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedRatio == ratio
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppThemeService.accent, AppThemeService.accentLight],
                                    startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(AppThemeService.surface),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Frame preview

    // GeometryReader gives us the exact available size so the image can be given an
    // explicit frame — preventing scaledToFill from leaking a wider layout size upward.
    @ViewBuilder
    private var framePreview: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppThemeService.surface)

                if let image = frameImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    VStack(spacing: 10) {
                        ProgressView().tint(AppThemeService.textSecondary)
                        Text("Loading frame…")
                            .font(.caption)
                            .foregroundStyle(AppThemeService.textSecondary)
                    }
                }

                // Dims area outside the selected crop window
                CropOverlay(targetRatio: selectedRatio.ratio)
                    .animation(.easeInOut(duration: 0.2), value: selectedRatio)

                // Ratio badge
                VStack {
                    HStack {
                        Spacer()
                        Text(selectedRatio.rawValue)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(.black.opacity(0.55), in: Capsule())
                            .padding(12)
                    }
                    Spacer()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    // MARK: - Scrubber

    private var scrubberSection: some View {
        VStack(spacing: 8) {
            Slider(value: $currentTime, in: 0...max(duration, 0.001))
                .tint(AppThemeService.accent)

            HStack {
                Text(formatted(0))
                Spacer()
                Text(formatted(currentTime))
                    .foregroundStyle(.white).fontWeight(.semibold)
                Spacer()
                Text(formatted(duration))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(AppThemeService.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppThemeService.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button("Back") { vm.goBack() }
                .buttonStyle(SecondaryButtonStyle())

            Button("Use This Frame") {
                guard let image = frameImage else { return }
                vm.framePicked(
                    videoURL: videoURL,
                    at: CMTime(seconds: currentTime, preferredTimescale: 600),
                    still: image,
                    ratio: selectedRatio
                )
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(frameImage == nil)
        }
    }

    // MARK: - Video loading

    private func loadVideo() async {
        let asset = AVURLAsset(url: videoURL)

        if let dur = try? await asset.load(.duration) {
            duration = max(CMTimeGetSeconds(dur), 0.001)
        }

        // Auto-detect native aspect ratio and default to closest preset
        if let track = try? await asset.loadTracks(withMediaType: .video).first {
            let size = (try? await track.load(.naturalSize)) ?? CGSize(width: 16, height: 9)
            let t    = (try? await track.load(.preferredTransform)) ?? .identity
            let r    = CGRect(origin: .zero, size: size).applying(t)
            let native = abs(r.width) / max(abs(r.height), 1)
            selectedRatio = AspectRatio.closest(to: native)
        }

        scheduleExtract(at: 0)
    }

    // MARK: - Frame extraction

    private func scheduleExtract(at time: Double) {
        extractTask?.cancel()
        extractTask = Task {
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled else { return }
            await extractFrame(at: time)
        }
    }

    @MainActor
    private func extractFrame(at time: Double) async {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        if #available(iOS 16, *) {
            frameImage = (try? await generator.image(at: cmTime)).map { UIImage(cgImage: $0.image) }
        } else {
            var actual = CMTime.zero
            frameImage = (try? generator.copyCGImage(at: cmTime, actualTime: &actual)).map(UIImage.init(cgImage:))
        }
    }

    private func formatted(_ t: Double) -> String {
        let s = Int(t)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

// MARK: - Crop overlay

private struct CropOverlay: View {
    let targetRatio: CGFloat

    var body: some View {
        GeometryReader { geo in
            let cropRect = centeredCropRect(in: geo.size, targetRatio: targetRatio)

            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.45)))
                ctx.blendMode = .destinationOut
                ctx.fill(Path(cropRect), with: .color(.white))
            }
            .compositingGroup()

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(.white.opacity(0.9), lineWidth: 1.5)
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)
        }
    }

    private func centeredCropRect(in size: CGSize, targetRatio: CGFloat) -> CGRect {
        let containerRatio = size.width / max(size.height, 1)
        let cropW: CGFloat
        let cropH: CGFloat
        if containerRatio > targetRatio {
            cropH = size.height
            cropW = cropH * targetRatio
        } else {
            cropW = size.width
            cropH = cropW / targetRatio
        }
        return CGRect(
            x: (size.width  - cropW) / 2,
            y: (size.height - cropH) / 2,
            width: cropW,
            height: cropH
        )
    }
}
