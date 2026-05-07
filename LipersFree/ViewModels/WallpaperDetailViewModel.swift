//
//  WallpaperDetailViewModel.swift
//  LipersFree
//

import Foundation
import Observation

@MainActor
@Observable
final class WallpaperDetailViewModel {

    var wallpapers: [Wallpaper] = []
    var currentIndex: Int = 0
    var isLoadingInitial: Bool = true
    var isLoadingMore: Bool = false
    var hasMore: Bool = true
    var errorMessage: String?
    var categories: [Category] = []
    private(set) var categoryId: Int

    private let apiService: APIService
    private let initialWallpaperId: Int
    private var nextPage: Int = 1

    var currentWallpaper: Wallpaper? {
        wallpapers.indices.contains(currentIndex) ? wallpapers[currentIndex] : nil
    }

    init(categoryId: Int, wallpaperId: Int, apiService: APIService? = nil) {
        self.categoryId = categoryId
        self.initialWallpaperId = wallpaperId
        self.apiService = apiService ?? APIService.shared
    }

    // MARK: - Loading

    /// Fetches the tapped wallpaper alone for instant playback, then loads
    /// the surrounding category list in the background.
    func loadInitial() async {
        if !wallpapers.isEmpty { return }

        do {
            let initial = try await apiService.fetchWallpaper(id: initialWallpaperId)
            wallpapers = [initial]
            currentIndex = 0
        } catch {
            errorMessage = error.localizedDescription
            isLoadingInitial = false
            return
        }

        isLoadingInitial = false
        await loadFirstPage()
    }

    private func loadFirstPage() async {
        do {
            let response = try await apiService.fetchWallpapers(categoryId: categoryId, page: 1)
            let pageItems = response.data

            if let idx = pageItems.firstIndex(where: { $0.id == initialWallpaperId }) {
                wallpapers = pageItems
                currentIndex = idx
            } else {
                // Initial wallpaper not in first page — keep it pinned at the front
                let initial = wallpapers.first
                let merged = (initial.map { [$0] } ?? []) + pageItems.filter { $0.id != initialWallpaperId }
                wallpapers = merged
                currentIndex = 0
            }

            hasMore = response.meta.current_page < response.meta.last_page
            nextPage = response.meta.current_page + 1
        } catch {
            // Silent — single wallpaper still works
        }
    }

    func loadMoreIfNeeded() {
        guard hasMore, !isLoadingMore else { return }
        guard currentIndex >= wallpapers.count - 4 else { return }
        Task { await loadNextPage() }
    }

    private func loadNextPage() async {
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let response = try await apiService.fetchWallpapers(categoryId: categoryId, page: nextPage)
            let existing = Set(wallpapers.map(\.id))
            wallpapers.append(contentsOf: response.data.filter { !existing.contains($0.id) })
            hasMore = response.meta.current_page < response.meta.last_page
            nextPage = response.meta.current_page + 1
        } catch {
            // Silent
        }
    }

    func setCurrentIndex(_ idx: Int) {
        guard wallpapers.indices.contains(idx), idx != currentIndex else { return }
        currentIndex = idx
        loadMoreIfNeeded()
    }

    // MARK: - Category drawer

    func loadCategoriesIfNeeded() async {
        guard categories.isEmpty else { return }
        do {
            categories = try await apiService.fetchCategories()
        } catch {
            // Silent — drawer will show empty state.
        }
    }

    func switchToCategory(_ category: Category) async {
        guard category.id != categoryId else { return }

        categoryId = category.id
        wallpapers = []
        currentIndex = 0
        nextPage = 1
        hasMore = true
        errorMessage = nil
        isLoadingInitial = true

        do {
            let response = try await apiService.fetchWallpapers(categoryId: category.id, page: 1)
            wallpapers = response.data
            currentIndex = 0
            hasMore = response.meta.current_page < response.meta.last_page
            nextPage = response.meta.current_page + 1
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingInitial = false
    }
}
