//
//  HomeResponse.swift
//  LipersFree
//

import Foundation

struct HomeSection: Identifiable {
    let category: Category
    let wallpapers: [Wallpaper]
    var id: Int { category.id }
}

extension HomeSection: Codable {
    enum CodingKeys: String, CodingKey {
        case category, wallpapers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decode(Category.self, forKey: .category)
        let raw = try container.decode([Wallpaper].self, forKey: .wallpapers)
        let wpCategory = WallpaperCategory(id: category.id, name: category.name)
        wallpapers = raw.map { $0.with(category: wpCategory) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(category, forKey: .category)
        try container.encode(wallpapers, forKey: .wallpapers)
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
