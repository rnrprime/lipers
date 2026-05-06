//
//  ExploreView.swift
//  LipersFree
//

import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = ExploreGridViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ZStack {
            AppThemeService.screenBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                title

                if !viewModel.categories.isEmpty {
                    categoryChips
                        .padding(.bottom, 12)
                }

                ZStack {
                    if viewModel.isLoading && viewModel.wallpapers.isEmpty {
                        loadingView
                    } else if let error = viewModel.errorMessage, viewModel.wallpapers.isEmpty {
                        errorView(message: error)
                    } else {
                        wallpaperGrid
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.loadInitial() }
    }

    // MARK: - Title

    private var title: some View {
        Text("Live Wallpapers")
            .font(.title3.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
    }

    // MARK: - Category chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(name: "All", thumbnailURL: nil, isSelected: viewModel.selectedCategoryId == nil)
                    .onTapGesture { viewModel.selectCategory(nil) }

                ForEach(viewModel.categories) { category in
                    chip(name: category.name, thumbnailURL: category.thumbnail, isSelected: viewModel.selectedCategoryId == category.id)
                        .onTapGesture { viewModel.selectCategory(category.id) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private func chip(name: String, thumbnailURL: String?, isSelected: Bool) -> some View {
        HStack(spacing: 7) {
            if let urlString = thumbnailURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        Circle().fill(Color.white.opacity(0.15))
                    }
                }
                .frame(width: 26, height: 26)
                .clipShape(Circle())
            }

            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            isSelected ? Color.white.opacity(0.16) : Color.white.opacity(0.06),
            in: Capsule()
        )
        .overlay(
            Capsule().stroke(
                isSelected ? AppThemeService.accent.opacity(0.8) : Color.white.opacity(0.1),
                lineWidth: 1
            )
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Grid

    private var wallpaperGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(viewModel.wallpapers) { wallpaper in
                    NavigationLink {
                        WallpaperDetailView(wallpaper: wallpaper)
                    } label: {
                        WallpaperCardView(wallpaper: wallpaper, width: nil, height: 270)
                    }
                    .buttonStyle(.plain)
                    .onAppear { viewModel.loadMoreIfNeeded(currentItem: wallpaper) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 20)

            if viewModel.isLoadingMore {
                ProgressView()
                    .tint(AppThemeService.accent)
                    .padding(.vertical, 20)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(AppThemeService.accent)
                .scaleEffect(1.3)
            Text("Loading wallpapers…")
                .font(.subheadline)
                .foregroundStyle(AppThemeService.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(AppThemeService.accent.opacity(0.8))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppThemeService.textSecondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task { await viewModel.retry() }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(AppThemeService.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { ExploreView() }
    }
}
