//
//  Category.swift
//  LipersFree
//
//  Created by Codex on 2/4/26.
//

import Foundation

struct Category: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String
    let thumbnail: String
}
