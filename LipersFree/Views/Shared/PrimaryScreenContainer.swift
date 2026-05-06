//
//  PrimaryScreenContainer.swift
//  LipersFree
//
//  Created by Codex on 1/4/26.
//

import SwiftUI

struct PrimaryScreenContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            AppThemeService.screenBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                content

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
