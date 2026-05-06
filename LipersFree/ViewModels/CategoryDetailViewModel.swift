//
//  CategoryDetailViewModel.swift
//  LipersFree
//
//  Created by Codex on 2/4/26.
//

import Combine
import Foundation

@MainActor
final class CategoryDetailViewModel: ObservableObject {
    @Published var wallpapers: [Wallpaper] = []
    @Published var currentPage = 1
    @Published var isLoading = false
    @Published var hasMore = true
    @Published var errorMessage: String?

    private let apiService: APIService
    private var activeCategoryId: Int?

    init(apiService: APIService? = nil) {
        self.apiService = apiService ?? APIService.shared
    }

    func fetchWallpapers(categoryId: Int) async {
        guard !isLoading else { return }

        activeCategoryId = categoryId
        wallpapers = []
        currentPage = 1
        hasMore = true
        errorMessage = nil

        await loadPage(categoryId: categoryId, page: 1, isInitialPage: true)
    }

    func loadMoreIfNeeded(currentItem: Wallpaper) {
        guard hasMore, !isLoading else { return }

        let thresholdIndex = max(wallpapers.count - 4, 0)
        guard let currentIndex = wallpapers.firstIndex(where: { $0.id == currentItem.id }),
              currentIndex >= thresholdIndex,
              let categoryId = activeCategoryId else {
            return
        }

        Task {
            await loadPage(categoryId: categoryId, page: currentPage, isInitialPage: false)
        }
    }

    private func loadPage(categoryId: Int, page: Int, isInitialPage: Bool) async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await apiService.fetchWallpapers(categoryId: categoryId, page: page)

            if isInitialPage {
                wallpapers = response.data
            } else {
                let existingIDs = Set(wallpapers.map(\.id))
                let newItems = response.data.filter { !existingIDs.contains($0.id) }
                wallpapers.append(contentsOf: newItems)
            }

            hasMore = response.meta.current_page < response.meta.last_page
            currentPage = response.meta.current_page + 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
