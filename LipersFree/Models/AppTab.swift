//
//  AppTab.swift
//  LipersFree
//
//  Created by Codex on 1/4/26.
//

import Foundation

enum AppTab: Hashable {
    case explore
    case maker
    case settings

    var title: String {
        switch self {
        case .explore:
            "Explore"
        case .maker:
            "Maker"
        case .settings:
            "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .explore:
            "globe"
        case .maker:
            "plus.square"
        case .settings:
            "gearshape"
        }
    }
}
