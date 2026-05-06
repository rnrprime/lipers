//
//  RootTabViewModel.swift
//  LipersFree
//
//  Created by Codex on 1/4/26.
//

import Combine
import Foundation

final class RootTabViewModel: ObservableObject {
    @Published var selectedTab: AppTab = .explore
}
