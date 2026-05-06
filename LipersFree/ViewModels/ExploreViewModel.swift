//
//  ExploreViewModel.swift
//  LipersFree
//
//  Created by Codex on 2/4/26.
//

import Combine
import Foundation

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var sections: [HomeSection] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var categories: [Category] {
        sections.map(\.category)
    }

    private let apiService: APIService
    private var hasLoaded = false

    init(apiService: APIService? = nil) {
        self.apiService = apiService ?? APIService.shared
    }

    func retry() async {
        hasLoaded = false
        await fetchHome()
    }

    func fetchHome() async {
        guard !isLoading, !hasLoaded else { return }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let response = try await apiService.fetchHome()
            sections = response.data
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
