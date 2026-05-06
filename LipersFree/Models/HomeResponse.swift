//
//  HomeResponse.swift
//  LipersFree
//
//  Created by Codex on 2/4/26.
//

import Foundation

struct HomeSection: Codable, Identifiable {
    let category: Category
    let wallpapers: [Wallpaper]

    var id: Int {
        category.id
    }
}

struct HomeMeta: Codable {
    let current_page: Int
    let last_page: Int
}

struct HomeResponse: Codable {
    let data: [HomeSection]
    let meta: HomeMeta
}
