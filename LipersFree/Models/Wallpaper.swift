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
    let is_premium: Bool
    // Decoded from /wallpapers and /wallpapers/{id}; injected from HomeSection for /home.
    var category: WallpaperCategory?

    func with(category: WallpaperCategory) -> Wallpaper {
        var copy = self
        copy.category = category
        return copy
    }
}
