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
                .padding(.bottom, 14)

            VStack(spacing: 10) {
                stepCard(
                    number: "01",
                    icon: "film",
                    color: AppThemeService.accent,
                    title: "Import Video",
                    description: "Pick any clip from your photo library"
                )
                stepConnector
                stepCard(
                    number: "02",
                    icon: "photo.on.rectangle",
                    color: .cyan,
                    title: "Pick a Key Frame",
                    description: "Scrub through and choose your still image"
                )
                stepConnector
                stepCard(
                    number: "03",
                    icon: "livephoto",
                    color: .green,
                    title: "Save as Live Photo",
                    description: "Trim the clip, then export to Camera Roll"
                )
            }
            .padding(.horizontal, 20)
        }
    }

    private var stepConnector: some View {
        HStack(spacing: 6) {
            Spacer()
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(AppThemeService.textSecondary.opacity(0.35))
                    .frame(width: 3, height: 3)
            }
            Spacer()
        }
    }

    private func stepCard(number: String, icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            // Icon block
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 54, height: 54)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(color)
            }

            // Text block
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(AppThemeService.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Step number badge
            Text(number)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.12), in: Capsule())
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppThemeService.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(color.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

struct MakerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { MakerView() }
    }
}
