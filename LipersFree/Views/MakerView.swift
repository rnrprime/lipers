//
//  MakerView.swift
//  LipersFree
//

import SwiftUI

// MARK: - Root

struct MakerView: View {
    @State private var vm = MakerViewModel()

    var body: some View {
        ZStack {
            AppThemeService.screenBackground.ignoresSafeArea()

            switch vm.step {
            case .landing:
                MakerLandingView(vm: vm)
            case .frameSelection(let url):
                MakerFrameStepView(vm: vm, videoURL: url)
            case .preview(let url, let time, let still, let ratio):
                MakerPreviewStepView(vm: vm, videoURL: url, frameTime: time, still: still, ratio: ratio)
            }
        }
        .id(vm.step.index)
        .animation(.easeInOut(duration: 0.25), value: vm.step.index)
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottom) {
            if let toast = vm.toast {
                ToastView(toast: toast)
                    .padding(.bottom, 96)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35), value: vm.toast)
    }
}

// MARK: - Landing

private struct MakerLandingView: View {
    var vm: MakerViewModel
    @State private var showPicker = false

    var body: some View {
        VStack(spacing: 0) {
            header

            Spacer()

            heroSection

            Spacer()

            howItWorks

            Spacer(minLength: 40)
        }
        .sheet(isPresented: $showPicker) {
            VideoPicker { url in vm.videoSelected(url) }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Maker")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)
            Text("Turn any video into a Live Wallpaper")
                .font(.subheadline)
                .foregroundStyle(AppThemeService.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    // MARK: Hero CTA

    private var heroSection: some View {
        VStack(spacing: 20) {
            Button { showPicker = true } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppThemeService.accent, AppThemeService.accentLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)
                        .shadow(color: AppThemeService.accent.opacity(0.5), radius: 20, y: 8)

                    Image(systemName: "plus")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

            VStack(spacing: 6) {
                Text("Import Video")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Select a clip from your library")
                    .font(.subheadline)
                    .foregroundStyle(AppThemeService.textSecondary)
            }
        }
    }

    // MARK: How it works

    private var howItWorks: some View {
        VStack(spacing: 0) {
            Text("HOW IT WORKS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppThemeService.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            VStack(spacing: 1) {
                stepRow(icon: "film",         color: AppThemeService.accent,      number: "1", text: "Pick a video from your library")
                stepRow(icon: "photo",        color: .cyan,                       number: "2", text: "Choose the still key frame")
                stepRow(icon: "livephoto",    color: .green,                      number: "3", text: "Preview and save as Live Photo")
            }
            .background(AppThemeService.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 20)
        }
    }

    private func stepRow(icon: String, color: Color, number: String, text: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(color)
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)

            Spacer()

            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppThemeService.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Preview

struct MakerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { MakerView() }
    }
}
