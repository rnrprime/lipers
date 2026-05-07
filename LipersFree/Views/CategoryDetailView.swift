//
//  CategoryDetailView.swift
//  LipersFree
//
//  Created by Codex on 2/4/26.
//

import SwiftUI

struct CategoryDetailView: View {
    let categoryId: Int
    let categoryName: String

    @StateObject private var viewModel = CategoryDetailViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            AppThemeService.screenBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                if viewModel.isLoading && viewModel.wallpapers.isEmpty {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 48)
                } else if let errorMessage = viewModel.errorMessage,
                          viewModel.wallpapers.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(.red.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 24)
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(viewModel.wallpapers) { wallpaper in
                            NavigationLink {
                                WallpaperDetailView(
                                    categoryId: categoryId,
                                    wallpaperId: wallpaper.id
                                )
                            } label: {
                                WallpaperCardView(
                                    wallpaper: wallpaper,
                                    width: nil,
                                    height: 250
                                )
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                viewModel.loadMoreIfNeeded(currentItem: wallpaper)
                            }
                        }
                    }
                    .padding(.top, 20)

                    if viewModel.isLoading && !viewModel.wallpapers.isEmpty {
                        ProgressView()
                            .tint(.white)
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.fetchWallpapers(categoryId: categoryId, categoryName: categoryName)
        }
    }
}

struct CategoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CategoryDetailView(categoryId: 4, categoryName: "Abstract")
        }
    }
}
