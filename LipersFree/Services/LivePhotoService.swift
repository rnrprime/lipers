//
//  LivePhotoService.swift
//  LipersFree
//

import Foundation
import Photos

enum LivePhotoServiceError: LocalizedError {
    case invalidURL
    case downloadFailed
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid file URL."
        case .downloadFailed: "Failed to download wallpaper files."
        case .permissionDenied: "Photo library access denied. Enable it in Settings to save wallpapers."
        }
    }
}

final class LivePhotoService {
    static let shared = LivePhotoService()

    func saveToPhotos(imageURLString: String, videoURLString: String) async throws {
        guard await requestPermission() else {
            throw LivePhotoServiceError.permissionDenied
        }

        guard let imageURL = URL(string: imageURLString),
              let videoURL = URL(string: videoURLString) else {
            throw LivePhotoServiceError.invalidURL
        }

        async let localImage = downloadFile(from: imageURL, ext: "jpg")
        async let localVideo = downloadFile(from: videoURL, ext: "mov")

        let (imageFile, videoFile) = try await (localImage, localVideo)
        try await saveAsLivePhoto(imageURL: imageFile, videoURL: videoFile)
    }

    private func downloadFile(from url: URL, ext: String) async throws -> URL {
        let (tempURL, response) = try await URLSession.shared.download(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw LivePhotoServiceError.downloadFailed
        }
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.moveItem(at: tempURL, to: dest)
        return dest
    }

    private func saveAsLivePhoto(imageURL: URL, videoURL: URL) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, fileURL: imageURL, options: nil)
            let opts = PHAssetResourceCreationOptions()
            opts.shouldMoveFile = true
            request.addResource(with: .pairedVideo, fileURL: videoURL, options: opts)
        }
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
}
