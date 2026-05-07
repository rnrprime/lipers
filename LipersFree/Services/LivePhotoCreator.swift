//
//  LivePhotoCreator.swift
//  LipersFree
//

import AVFoundation
import Foundation
import ImageIO
import Photos
import UIKit
import UniformTypeIdentifiers

enum LivePhotoCreatorError: LocalizedError {
    case frameExtractionFailed
    case jpegWriteFailed
    case videoExportFailed
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .frameExtractionFailed: "Could not extract a frame from the video."
        case .jpegWriteFailed:       "Could not write the still image."
        case .videoExportFailed:     "Could not process the video."
        case .permissionDenied:      "Photo library access denied. Enable it in Settings."
        }
    }
}

final class LivePhotoCreator {
    static let shared = LivePhotoCreator()
    private init() {}

    func createAndSave(
        videoURL: URL,
        frameTime: CMTime,
        ratio: AspectRatio,
        trimRange: CMTimeRange? = nil
    ) async throws {
        guard await requestPermission() else { throw LivePhotoCreatorError.permissionDenied }
        let contentID = UUID().uuidString

        // Clamp the still frame to the trim range
        let clampedFrame: CMTime
        if let range = trimRange {
            let s = CMTimeGetSeconds(range.start)
            let e = CMTimeGetSeconds(range.end)
            clampedFrame = CMTime(seconds: max(s, min(CMTimeGetSeconds(frameTime), e)),
                                  preferredTimescale: 600)
        } else {
            clampedFrame = frameTime
        }

        let jpegURL = try await makeJPEG(from: videoURL, at: clampedFrame,
                                         contentID: contentID, ratio: ratio)
        let movURL  = try await makeMOV(from: videoURL, contentID: contentID,
                                        ratio: ratio, trimRange: trimRange)
        try await saveAsLivePhoto(imageURL: jpegURL, videoURL: movURL)
    }

    // MARK: - Frame extraction (public, used for preview)

    func extractFrame(from videoURL: URL, at time: CMTime) async throws -> UIImage {
        let gen = makeGenerator(for: videoURL)
        guard let cg = try await extractCGImage(gen: gen, at: time) else {
            throw LivePhotoCreatorError.frameExtractionFailed
        }
        return UIImage(cgImage: cg)
    }

    // MARK: - JPEG with Apple Live Photo content identifier + center crop

    private func makeJPEG(from videoURL: URL, at time: CMTime,
                           contentID: String, ratio: AspectRatio) async throws -> URL {
        let gen = makeGenerator(for: videoURL)
        guard let cgImage = try await extractCGImage(gen: gen, at: time) else {
            throw LivePhotoCreatorError.frameExtractionFailed
        }

        let cropped = centerCrop(cgImage, to: ratio)

        let dest = tmp("jpg")
        guard let cgDest = CGImageDestinationCreateWithURL(
            dest as CFURL, UTType.jpeg.identifier as CFString, 1, nil
        ) else { throw LivePhotoCreatorError.jpegWriteFailed }

        CGImageDestinationAddImage(cgDest, cropped, [
            kCGImagePropertyMakerAppleDictionary as String: ["17": contentID]
        ] as CFDictionary)

        guard CGImageDestinationFinalize(cgDest) else { throw LivePhotoCreatorError.jpegWriteFailed }
        return dest
    }

    /// Center-crops a CGImage to the given AspectRatio.
    private func centerCrop(_ image: CGImage, to ratio: AspectRatio) -> CGImage {
        let w = CGFloat(image.width)
        let h = CGFloat(image.height)
        let sourceRatio = w / h
        let targetRatio = ratio.ratio

        let cropRect: CGRect
        if sourceRatio > targetRatio {
            // Source wider → trim left/right
            let newW = h * targetRatio
            cropRect = CGRect(x: (w - newW) / 2, y: 0, width: newW, height: h)
        } else {
            // Source taller → trim top/bottom
            let newH = w / targetRatio
            cropRect = CGRect(x: 0, y: (h - newH) / 2, width: w, height: newH)
        }

        return image.cropping(to: cropRect) ?? image
    }

    // MARK: - MOV re-export with content identifier + optional crop/trim

    private func makeMOV(from videoURL: URL, contentID: String,
                          ratio: AspectRatio, trimRange: CMTimeRange?) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)

        // Load video track properties
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            throw LivePhotoCreatorError.videoExportFailed
        }
        let naturalSize      = (try? await videoTrack.load(.naturalSize))        ?? CGSize(width: 1920, height: 1080)
        let preferredTransform = (try? await videoTrack.load(.preferredTransform)) ?? .identity
        let nominalFPS       = (try? await videoTrack.load(.nominalFrameRate))    ?? 30
        let assetDuration    = (try? await asset.load(.duration)) ?? CMTime(seconds: 60, preferredTimescale: 600)

        // Build a video-only composition so the exported Live Photo has no audio.
        let composition = AVMutableComposition()
        guard let compVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else { throw LivePhotoCreatorError.videoExportFailed }

        let sourceRange = trimRange ?? CMTimeRange(start: .zero, duration: assetDuration)
        do {
            try compVideoTrack.insertTimeRange(sourceRange, of: videoTrack, at: .zero)
        } catch {
            throw LivePhotoCreatorError.videoExportFailed
        }
        compVideoTrack.preferredTransform = preferredTransform

        // Effective display size after applying orientation transform
        let effectiveRect = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
        let effectiveSize = CGSize(width: abs(effectiveRect.width), height: abs(effectiveRect.height))
        let nativeRatio   = effectiveSize.width / max(effectiveSize.height, 1)
        let needsCrop     = abs(nativeRatio - ratio.ratio) > 0.05

        // Always re-encode (never passthrough) so the video-only composition is
        // honored and no audio leaks through from the source asset.
        guard let session = AVAssetExportSession(asset: composition,
                                                  presetName: AVAssetExportPresetHighestQuality) else {
            throw LivePhotoCreatorError.videoExportFailed
        }

        // Content identifier metadata
        let item = AVMutableMetadataItem()
        item.keySpace = .quickTimeMetadata
        item.key      = "com.apple.quicktime.content.identifier" as NSString
        item.value    = contentID as NSString
        item.dataType = "com.apple.metadata.datatype.UTF-8"

        let dest = tmp("mov")
        session.outputURL      = dest
        session.outputFileType = .mov
        session.metadata       = [item]

        if needsCrop {
            let renderSize = computeRenderSize(effectiveSize: effectiveSize, targetRatio: ratio.ratio)
            let transform  = buildCenterCropTransform(naturalSize: naturalSize,
                                                       preferredTransform: preferredTransform,
                                                       renderSize: renderSize)

            let videoComp  = AVMutableVideoComposition()
            videoComp.renderSize    = renderSize
            videoComp.frameDuration = CMTime(value: 1, timescale: CMTimeScale(max(nominalFPS, 1)))

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

            let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: compVideoTrack)
            layer.setTransform(transform, at: .zero)
            instruction.layerInstructions = [layer]
            videoComp.instructions = [instruction]

            session.videoComposition = videoComp
        }

        return try await withCheckedThrowingContinuation { cont in
            session.exportAsynchronously {
                switch session.status {
                case .completed: cont.resume(returning: dest)
                default:         cont.resume(throwing: session.error ?? LivePhotoCreatorError.videoExportFailed)
                }
            }
        }
    }

    /// Computes the output pixel size that fits the target ratio using the source's
    /// larger dimension — no upscaling, no wasted pixels.
    private func computeRenderSize(effectiveSize: CGSize, targetRatio: CGFloat) -> CGSize {
        let sourceRatio = effectiveSize.width / max(effectiveSize.height, 1)
        if sourceRatio > targetRatio {
            // Source wider → constrain by height
            let h = effectiveSize.height
            return CGSize(width: (h * targetRatio).rounded(), height: h.rounded())
        } else {
            // Source taller → constrain by width
            let w = effectiveSize.width
            return CGSize(width: w.rounded(), height: (w / targetRatio).rounded())
        }
    }

    /// Builds an AVFoundation layer transform that applies the track's preferred
    /// orientation, then scales + centers the content to fill renderSize (aspect fill).
    private func buildCenterCropTransform(naturalSize: CGSize,
                                           preferredTransform: CGAffineTransform,
                                           renderSize: CGSize) -> CGAffineTransform {
        let effectiveRect = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
        let effectiveSize = CGSize(width: abs(effectiveRect.width), height: abs(effectiveRect.height))

        let scale = max(renderSize.width  / max(effectiveSize.width,  1),
                        renderSize.height / max(effectiveSize.height, 1))

        let scaledW = effectiveSize.width  * scale
        let scaledH = effectiveSize.height * scale
        let tx = (renderSize.width  - scaledW) / 2
        let ty = (renderSize.height - scaledH) / 2

        return preferredTransform
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
            .concatenating(CGAffineTransform(translationX: tx, y: ty))
    }

    // MARK: - Save paired Live Photo

    private func saveAsLivePhoto(imageURL: URL, videoURL: URL) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            let req = PHAssetCreationRequest.forAsset()
            req.addResource(with: .photo, fileURL: imageURL, options: nil)
            let opts = PHAssetResourceCreationOptions()
            opts.shouldMoveFile = true
            req.addResource(with: .pairedVideo, fileURL: videoURL, options: opts)
        }
    }

    // MARK: - Shared helpers

    private func extractCGImage(gen: AVAssetImageGenerator, at time: CMTime) async throws -> CGImage? {
        if #available(iOS 16, *) {
            return try await gen.image(at: time).image
        } else {
            var actual = CMTime.zero
            return try? gen.copyCGImage(at: time, actualTime: &actual)
        }
    }

    private func makeGenerator(for videoURL: URL) -> AVAssetImageGenerator {
        let gen = AVAssetImageGenerator(asset: AVURLAsset(url: videoURL))
        gen.appliesPreferredTrackTransform = true
        gen.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        gen.requestedTimeToleranceAfter  = CMTime(seconds: 0.1, preferredTimescale: 600)
        return gen
    }

    private func requestPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited: return true
        case .notDetermined:
            let new = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return new == .authorized || new == .limited
        default: return false
        }
    }

    private func tmp(_ ext: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
    }
}
