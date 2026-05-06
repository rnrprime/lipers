//
//  CategoryCardView.swift
//  LipersFree
//

import SwiftUI

struct CategoryCardView: View {
    let category: Category

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: category.thumbnail)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder
                case .empty:
                    placeholder.overlay {
                        ProgressView().tint(AppThemeService.accent)
                    }
                @unknown default:
                    placeholder
                }
            }
            .frame(width: 105, height: 135)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )

            Text(category.name)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
        }
        .frame(width: 105, height: 135)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var placeholder: some View {
        Rectangle()
            .fill(AppThemeService.surface)
            .overlay {
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.3))
            }
    }
}

struct CategoryCardView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryCardView(
            category: Category(
                id: 1,
                name: "Abstract",
                slug: "abstract",
                thumbnail: "https://picsum.photos/300/400"
            )
        )
        .padding()
        .background(AppThemeService.screenBackground)
        .preferredColorScheme(.dark)
    }
}
