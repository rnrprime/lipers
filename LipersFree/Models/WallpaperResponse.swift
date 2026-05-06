//
//  WallpaperResponse.swift
//  LipersFree
//

import Foundation

struct WallpaperMeta: Codable {
    let current_page: Int
    let last_page: Int
    let per_page: Int
    let total: Int
}

struct WallpaperLinks: Codable {
    let first: String?
    let last: String?
    let prev: String?
    let next: String?
}

struct WallpaperResponse: Codable {
    let data: [Wallpaper]
    let links: WallpaperLinks
    let meta: WallpaperMeta
}
