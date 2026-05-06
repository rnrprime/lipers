//
//  Wallpaper.swift
//  LipersFree
//

import Foundation

struct WallpaperCategory: Codable {
    let id: Int
    let name: String
}

struct Wallpaper: Codable, Identifiable {
    let id: Int
    let title: String
    let preview_image: String
    let file_url: String
    let live_image_url: String?
    let live_video_url: String?
    let is_premium: Bool
    let category: WallpaperCategory?
}
