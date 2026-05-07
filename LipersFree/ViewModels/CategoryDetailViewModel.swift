//
//  CategoryDetailViewModel.swift
//  LipersFree
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
    private var activeCategoryName: String = ""

    init(apiService: APIService? = nil) {
        self.apiService = apiService ?? APIService.shared
    }

    func fetchWallpapers(categoryId: Int, categoryName: String) async {
        guard !isLoading else { return }

        activeCategoryId = categoryId
        activeCategoryName = categoryName
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

        let wpCategory = WallpaperCategory(id: categoryId, name: activeCategoryName)

        do {
            let response = try await apiService.fetchWallpapers(categoryId: categoryId, page: page)
            let tagged = response.data.map { $0.with(category: wpCategory) }

            if isInitialPage {
                wallpapers = tagged
            } else {
                let existingIDs = Set(wallpapers.map(\.id))
                wallpapers.append(contentsOf: tagged.filter { !existingIDs.contains($0.id) })
            }

            hasMore = response.meta.current_page < response.meta.last_page
            currentPage = response.meta.current_page + 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
