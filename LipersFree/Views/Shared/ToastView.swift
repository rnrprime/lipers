//
//  ToastView.swift
//  LipersFree
//

import SwiftUI

struct Toast: Equatable {
    let message: String
    let isError: Bool
}

struct ToastView: View {
    let toast: Toast

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                .foregroundStyle(toast.isError ? AppThemeService.destructive : AppThemeService.accent)
            Text(toast.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
