//
//  ExploreGridViewModel.swift
//  LipersFree
//

import Combine
import Foundation

@MainActor
final class ExploreGridViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var wallpapers: [Wallpaper] = []
    @Published var selectedCategoryId: Int? = nil
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMore = true
    @Published var errorMessage: String?

    private var currentPage = 1
    private let apiService: APIService

    init(apiService: APIService? = nil) {
        self.apiService = apiService ?? APIService.shared
    }

    func loadInitial() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let categoriesTask = apiService.fetchCategories()
            async let wallpapersTask = apiService.fetchWallpapers(categoryId: nil, page: 1)
            let (cats, response) = try await (categoriesTask, wallpapersTask)
            categories = cats
            wallpapers = response.data
            hasMore = response.meta.current_page < response.meta.last_page
            currentPage = 2
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectCategory(_ id: Int?) {
        guard selectedCategoryId != id else { return }
        selectedCategoryId = id
        wallpapers = []
        currentPage = 1
        hasMore = true
        errorMessage = nil
        Task { await loadFilteredPage() }
    }

    func loadMoreIfNeeded(currentItem: Wallpaper) {
        guard hasMore, !isLoadingMore, !isLoading else { return }
        let threshold = max(wallpapers.count - 6, 0)
        guard let idx = wallpapers.firstIndex(where: { $0.id == currentItem.id }),
              idx >= threshold else { return }
        Task { await loadNextPage() }
    }

    func retry() async {
        wallpapers = []
        currentPage = 1
        hasMore = true
        errorMessage = nil
        await loadInitial()
    }

    private func loadFilteredPage() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await apiService.fetchWallpapers(categoryId: selectedCategoryId, page: 1)
            wallpapers = response.data
            hasMore = response.meta.current_page < response.meta.last_page
            currentPage = 2
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadNextPage() async {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let response = try await apiService.fetchWallpapers(categoryId: selectedCategoryId, page: currentPage)
            let existing = Set(wallpapers.map(\.id))
            wallpapers.append(contentsOf: response.data.filter { !existing.contains($0.id) })
            hasMore = response.meta.current_page < response.meta.last_page
            currentPage += 1
        } catch { }
    }
}
