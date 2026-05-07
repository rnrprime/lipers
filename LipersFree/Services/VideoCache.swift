//
//  VideoCache.swift
//  LipersFree
//

import Foundation

/// Downloads remote .mov files to the Caches directory and reuses them on
/// subsequent requests so swiping back to a wallpaper plays instantly.
@MainActor
final class VideoCache {
    static let shared = VideoCache()

    private var localURLs: [String: URL] = [:]
    private var inflight: [String: Task<URL, Error>] = [:]
    private var order: [String] = []
    private let maxEntries = 12

    private let directory: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = caches.appendingPathComponent("wallpaper_videos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private init() {}

    func localURL(for remote: URL) async throws -> URL {
        let key = remote.absoluteString

        if let existing = localURLs[key], FileManager.default.fileExists(atPath: existing.path) {
            touch(key)
            return existing
        }

        if let task = inflight[key] {
            return try await task.value
        }

        let dest = directory.appendingPathComponent(filename(for: remote))

        let task = Task<URL, Error> {
            let (tmp, _) = try await URLSession.shared.download(from: remote)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: tmp, to: dest)
            return dest
        }
        inflight[key] = task

        do {
            let url = try await task.value
            inflight[key] = nil
            localURLs[key] = url
            touch(key)
            evictIfNeeded()
            return url
        } catch {
            inflight[key] = nil
            throw error
        }
    }

    private func filename(for remote: URL) -> String {
        let hash = abs(remote.absoluteString.hashValue)
        let ext = remote.pathExtension.isEmpty ? "mov" : remote.pathExtension
        return "\(hash).\(ext)"
    }

    private func touch(_ key: String) {
        order.removeAll { $0 == key }
        order.append(key)
    }

    private func evictIfNeeded() {
        while order.count > maxEntries {
            let oldest = order.removeFirst()
            if let url = localURLs.removeValue(forKey: oldest) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}
