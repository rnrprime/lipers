//
//  VideoTrimmerView.swift
//  LipersFree
//

import AVFoundation
import SwiftUI

struct VideoTrimmerView: View {
    let videoURL: URL
    let duration: Double
    @Binding var trimStart: Double
    @Binding var trimEnd: Double
    /// Called when the user releases a trim handle so the caller can seek.
    var onTrimEnd: (() -> Void)? = nil

    @State private var thumbnails: [UIImage] = []
    @State private var activeHandle: TrimHandle? = nil

    private enum TrimHandle { case start, end }
    private let stripHeight: CGFloat = 56
    private let handleWidth: CGFloat = 14
    private let thumbnailCount = 10

    var body: some View {
        GeometryReader { geo in
            let w   = geo.size.width
            let sx  = position(of: trimStart, in: w)
            let ex  = position(of: trimEnd,   in: w)

            ZStack(alignment: .leading) {
                // Thumbnail filmstrip
                filmstrip(width: w)

                // Dim — before trim start
                if sx > 0 {
                    Color.black.opacity(0.6)
                        .frame(width: sx, height: stripHeight)
                }

                // Dim — after trim end
                if ex < w {
                    Color.black.opacity(0.6)
                        .frame(width: w - ex, height: stripHeight)
                        .offset(x: ex)
                }

                // Selection border
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(.white, lineWidth: 2)
                    .frame(width: max(ex - sx, 0), height: stripHeight)
                    .offset(x: sx)

                // Left (start) handle
                trimHandle
                    .frame(width: handleWidth, height: stripHeight)
                    .offset(x: sx)

                // Right (end) handle
                trimHandle
                    .frame(width: handleWidth, height: stripHeight)
                    .offset(x: ex - handleWidth)
            }
            .frame(width: w, height: stripHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        // Decide which handle on first contact
                        if activeHandle == nil {
                            let ox = value.startLocation.x
                            activeHandle = abs(ox - sx) <= abs(ox - ex) ? .start : .end
                        }

                        let frac = max(0, min(value.location.x / w, 1))
                        let secs = frac * max(duration, 0.001)

                        switch activeHandle {
                        case .start: trimStart = min(secs, trimEnd - 0.5)
                        case .end:   trimEnd   = max(secs, trimStart + 0.5)
                        case nil:    break
                        }
                    }
                    .onEnded { _ in
                        activeHandle = nil
                        onTrimEnd?()
                    }
            )
        }
        .frame(height: stripHeight)
        .task { await loadThumbnails() }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func filmstrip(width: CGFloat) -> some View {
        if thumbnails.isEmpty {
            Rectangle()
                .fill(AppThemeService.surface)
                .frame(width: width, height: stripHeight)
                .overlay(ProgressView().tint(.white).scaleEffect(0.75))
        } else {
            let fw = width / CGFloat(thumbnails.count)
            HStack(spacing: 0) {
                ForEach(Array(thumbnails.enumerated()), id: \.offset) { _, img in
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: fw, height: stripHeight)
                        .clipped()
                }
            }
            .frame(width: width, height: stripHeight)
        }
    }

    private var trimHandle: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(.white)
            .overlay(
                VStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 3, height: 3)
                    }
                }
            )
    }

    // MARK: - Helpers

    private func position(of time: Double, in width: CGFloat) -> CGFloat {
        CGFloat(time / max(duration, 0.001)) * width
    }

    private func loadThumbnails() async {
        let asset = AVURLAsset(url: videoURL)
        guard let dur = try? await asset.load(.duration) else { return }
        let total = CMTimeGetSeconds(dur)
        guard total > 0 else { return }

        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.requestedTimeToleranceBefore = CMTime(seconds: 0.5, preferredTimescale: 600)
        gen.requestedTimeToleranceAfter  = CMTime(seconds: 0.5, preferredTimescale: 600)
        gen.maximumSize = CGSize(width: 80, height: 80)

        for i in 0..<thumbnailCount {
            let t = CMTime(seconds: (Double(i) + 0.5) * total / Double(thumbnailCount),
                           preferredTimescale: 600)
            if #available(iOS 16, *) {
                if let result = try? await gen.image(at: t) {
                    thumbnails.append(UIImage(cgImage: result.image))
                }
            } else {
                var actual = CMTime.zero
                if let img = try? gen.copyCGImage(at: t, actualTime: &actual) {
                    thumbnails.append(UIImage(cgImage: img))
                }
            }
        }
    }
}
