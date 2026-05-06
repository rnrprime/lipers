//
//  AspectRatio.swift
//  LipersFree
//

import CoreGraphics

enum AspectRatio: String, CaseIterable, Identifiable {
    case portrait  = "9:16"
    case square    = "1:1"
    case landscape = "16:9"

    var id: String { rawValue }

    /// Width ÷ Height
    var ratio: CGFloat {
        switch self {
        case .portrait:  return 9.0 / 16.0
        case .square:    return 1.0
        case .landscape: return 16.0 / 9.0
        }
    }

    /// Returns the case whose ratio is closest to the given value.
    static func closest(to value: CGFloat) -> AspectRatio {
        allCases.min { abs($0.ratio - value) < abs($1.ratio - value) } ?? .portrait
    }
}
