//
//  WallpaperDetailView.swift
//  LipersFree
//

import AVKit
import SwiftUI

private enum WorkState { case idle, downloading, setting }

struct WallpaperDetailView: View {
    let categoryId: Int
    let wallpaperId: Int

    @State private var vm: WallpaperDetailViewModel
    @State private var scrollIndex: Int?
    @State private var workState: WorkState = .idle
    @State private var showInstructions = false
    @State private var toast: Toast?
    @State private var showSwipeHint = false
    @State private var showCategoryDrawer = false
    @State private var hasAutoPlayedInitial = false

    @AppStorage("hasSeenSwipeHint") private var hasSeenSwipeHint = false
    @Environment(\.dismiss) private var dismiss

    init(categoryId: Int, wallpaperId: Int) {
        self.categoryId = categoryId
        self.wallpaperId = wallpaperId
        self._vm = State(initialValue: WallpaperDetailViewModel(categoryId: categoryId, wallpaperId: wallpaperId))
    }

    /// Reads safe area directly from the key window. `geo.safeAreaInsets`
    /// returns 0 inside an `.ignoresSafeArea()` GeometryReader in this
    /// navigation context, so we bypass it.
    private var deviceTopInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first(where: { $0.isKeyWindow })?
            .safeAreaInsets.top ?? 47
    }

    var body: some View {
        GeometryReader { geo in
            let topInset = deviceTopInset
            ZStack {
                Color.black

                if vm.isLoadingInitial {
                    ProgressView().tint(.white)
                } else if vm.wallpapers.isEmpty {
                    errorView
                } else {
                    pager(size: geo.size, topInset: topInset)
                    overlay(topInset: topInset)
                    if showSwipeHint { swipeHintView }
                }

                if let toast {
                    VStack {
                        Spacer()
                        ToastView(toast: toast)
                            .padding(.bottom, 220)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                if showCategoryDrawer {
                    CategoryDrawerView(
                        categories: vm.categories,
                        selectedId: vm.categoryId,
                        topInset: topInset,
                        onClose: { dismissDrawer() },
                        onSelect: { category in
                            dismissDrawer()
                            Task {
                                await vm.switchToCategory(category)
                                scrollIndex = 0
                            }
                        }
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .zIndex(2)
                }
            }
        }
        .ignoresSafeArea()
        .animation(.spring(response: 0.35), value: toast)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task { await runInitialLoad() }
        .onChange(of: scrollIndex) { _, new in
            guard let new else { return }
            vm.setCurrentIndex(new)
            if showSwipeHint { dismissHint() }
        }
        .sheet(isPresented: $showInstructions) {
            SetWallpaperInstructionsView()
        }
    }

    // MARK: - Initial load

    private func runInitialLoad() async {
        await vm.loadInitial()
        scrollIndex = vm.currentIndex

        Task { await vm.loadCategoriesIfNeeded() }

        guard !hasSeenSwipeHint else { return }
        try? await Task.sleep(for: .milliseconds(600))
        withAnimation(.easeIn(duration: 0.25)) { showSwipeHint = true }
        try? await Task.sleep(for: .seconds(4))
        if showSwipeHint { dismissHint() }
    }

    private func dismissHint() {
        hasSeenSwipeHint = true
        withAnimation(.easeOut(duration: 0.3)) { showSwipeHint = false }
    }

    private func openDrawer() {
        Task { await vm.loadCategoriesIfNeeded() }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showCategoryDrawer = true
        }
    }

    private func dismissDrawer() {
        withAnimation(.easeInOut(duration: 0.25)) { showCategoryDrawer = false }
    }

    // MARK: - Pager

    private func pager(size: CGSize, topInset: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(Array(vm.wallpapers.enumerated()), id: \.element.id) { index, wallpaper in
                    WallpaperPageView(
                        wallpaper: wallpaper,
                        isCurrent: index == vm.currentIndex,
                        topInset: topInset,
                        shouldAutoPlay: !hasAutoPlayedInitial && wallpaper.id == wallpaperId,
                        onAutoPlayed: { hasAutoPlayedInitial = true }
                    )
                    .frame(width: size.width, height: size.height)
                    .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrollIndex)
        .ignoresSafeArea()
    }

    // MARK: - Overlay

    @ViewBuilder
    private func overlay(topInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            dismissButton
                .padding(.top, topInset + 12)
                .padding(.horizontal, 20)

            Spacer()

            VStack(spacing: 0) {
                actionButtons
                    .padding(.top, 28)
                    .padding(.bottom, 16)
                thumbnailStrip
                    .padding(.bottom, 12)
            }
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var dismissButton: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(.black.opacity(0.4), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        HStack(spacing: 0) {
            Spacer()
            circleButton(icon: "square.grid.2x2.fill",
                         isLoading: false,
                         diameter: 52) { openDrawer() }
            Spacer()
            circleButton(icon: "arrow.down",
                         isLoading: workState == .downloading,
                         diameter: 68) { Task { await downloadWallpaper() } }
            Spacer()
            circleButton(icon: "square.and.arrow.down.on.square",
                         isLoading: workState == .setting,
                         diameter: 52) { Task { await setWallpaper() } }
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func circleButton(icon: String, isLoading: Bool, diameter: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle().fill(.black.opacity(0.35)).frame(width: diameter, height: diameter)
                Circle().stroke(.white.opacity(0.75), lineWidth: 1.5).frame(width: diameter, height: diameter)
                if isLoading {
                    ProgressView().tint(.white).scaleEffect(0.75)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: diameter * 0.3, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(workState != .idle)
    }

    // MARK: - Thumbnail strip

    private var thumbnailStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 5) {
                    ForEach(Array(vm.wallpapers.enumerated()), id: \.element.id) { index, wp in
                        thumbCard(wp, isSelected: index == vm.currentIndex)
                            .id(index)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    scrollIndex = index
                                }
                            }
                    }
                }
                .padding(.horizontal, 14)
            }
            .frame(height: 104)
            .onChange(of: vm.currentIndex) { _, new in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(new, anchor: .center)
                }
            }
        }
    }

    private func thumbCard(_ wp: Wallpaper, isSelected: Bool) -> some View {
        ZStack {
            AsyncImage(url: URL(string: wp.preview_image)) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default:                Rectangle().fill(.white.opacity(0.08))
                }
            }
            .frame(width: 64, height: 92)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? .white : .white.opacity(0.12),
                            lineWidth: isSelected ? 2 : 0.5)
            )

            if isSelected {
                Circle()
                    .fill(.black.opacity(0.55))
                    .frame(width: 22, height: 22)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    // MARK: - Swipe hint

    private var swipeHintView: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(y: showSwipeHint ? -4 : 4)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: showSwipeHint)
                Text("Swipe for more")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }

            Rectangle()
                .fill(.white.opacity(0.18))
                .frame(width: 90, height: 1)

            VStack(spacing: 8) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Hold to preview")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
        .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Error

    private var errorView: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(.orange)
            Text(vm.errorMessage ?? "Failed to load wallpaper")
                .font(.subheadline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await vm.loadInitial() }
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Actions

    private func downloadWallpaper() async {
        guard let wp = vm.currentWallpaper else { return }
        workState = .downloading
        defer { workState = .idle }
        do {
            try await LivePhotoService.shared.saveToPhotos(
                imageURLString: wp.preview_image,
                videoURLString: wp.file_url
            )
            showToast("Saved to Photos ✓")
        } catch {
            showToast(error.localizedDescription, isError: true)
        }
    }

    private func setWallpaper() async {
        guard let wp = vm.currentWallpaper else { return }
        workState = .setting
        defer { workState = .idle }
        do {
            try await LivePhotoService.shared.saveToPhotos(
                imageURLString: wp.preview_image,
                videoURLString: wp.file_url
            )
            showInstructions = true
        } catch {
            showToast(error.localizedDescription, isError: true)
        }
    }

    private func showToast(_ message: String, isError: Bool = false) {
        withAnimation { toast = Toast(message: message, isError: isError) }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation { toast = nil }
        }
    }
}

// MARK: - Single page (one wallpaper)

private enum PageState {
    case loadingVideo
    case ready
    case playing
    case error
}

private struct WallpaperPageView: View {
    let wallpaper: Wallpaper
    let isCurrent: Bool
    let topInset: CGFloat
    let shouldAutoPlay: Bool
    let onAutoPlayed: () -> Void

    @State private var state: PageState = .loadingVideo
    @State private var player = AVPlayer()
    @State private var localVideoURL: URL?
    @State private var prepareTask: Task<Void, Never>?
    @State private var endObserver: (any NSObjectProtocol)?
    @State private var didAutoPlay = false

    var body: some View {
        ZStack {
            Color.black

            // Static preview is always rendered as the base layer so there's
            // no black flash when the video starts or ends.
            AsyncImage(url: URL(string: wallpaper.preview_image)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                case .empty:
                    ProgressView().tint(.white)
                case .failure:
                    Color.black
                @unknown default:
                    Color.black
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            if state == .playing {
                VideoPlayerView(player: player)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            badges
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.2) {
            startPlayback()
        } onPressingChanged: { pressing in
            if !pressing && state == .playing {
                stopPlayback()
            }
        }
        .onAppear { prepareIfNeeded() }
        .onDisappear {
            prepareTask?.cancel()
            prepareTask = nil
            stopPlayback()
        }
        .onChange(of: isCurrent) { _, current in
            if !current { stopPlayback() }
        }
    }

    @ViewBuilder
    private var badges: some View {
        VStack(spacing: 0) {
            Group {
                if state == .loadingVideo {
                    loadingBadge
                } else if state == .ready || state == .playing {
                    liveBadge(active: state == .playing)
                }
            }
            .padding(.top, topInset + 12)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func liveBadge(active: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "livephoto")
                .font(.system(size: 11, weight: .semibold))
            Text("LIVE")
                .font(.system(size: 11, weight: .heavy))
                .tracking(0.5)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial.opacity(active ? 1.0 : 0.7), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 0.5))
        .animation(.easeInOut(duration: 0.2), value: active)
    }

    private var loadingBadge: some View {
        HStack(spacing: 6) {
            ProgressView().tint(.white).scaleEffect(0.7)
            Text("Loading")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5))
    }

    // MARK: - State transitions

    private func prepareIfNeeded() {
        guard prepareTask == nil,
              localVideoURL == nil,
              let remote = URL(string: wallpaper.file_url) else { return }
        if state != .loadingVideo { state = .loadingVideo }
        prepareTask = Task {
            do {
                let local = try await VideoCache.shared.localURL(for: remote)
                guard !Task.isCancelled else { return }
                localVideoURL = local
                state = .ready

                if shouldAutoPlay && !didAutoPlay && isCurrent {
                    didAutoPlay = true
                    onAutoPlayed()
                    startPlayback()
                }
            } catch {
                guard !Task.isCancelled else { return }
                state = .error
            }
        }
    }

    private func startPlayback() {
        guard state == .ready, let local = localVideoURL else { return }

        let item = AVPlayerItem(url: local)
        player.replaceCurrentItem(with: item)
        player.seek(to: .zero)

        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            Task { @MainActor in stopPlayback() }
        }

        withAnimation(.easeInOut(duration: 0.2)) { state = .playing }
        player.play()
    }

    private func stopPlayback() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        if state == .playing {
            withAnimation(.easeInOut(duration: 0.2)) { state = .ready }
        }
    }
}

// MARK: - Category drawer

private struct CategoryDrawerView: View {
    let categories: [Category]
    let selectedId: Int
    let topInset: CGFloat
    let onClose: () -> Void
    let onSelect: (Category) -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onClose() }

            panel
                .frame(maxWidth: 320)
        }
    }

    private var panel: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, topInset + 12)
                .padding(.horizontal, 18)
                .padding(.bottom, 14)

            if categories.isEmpty {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(categories) { category in
                            row(for: category, isSelected: category.id == selectedId)
                                .onTapGesture { onSelect(category) }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(AppThemeService.detailBackground)
        .clipShape(.rect(bottomTrailingRadius: 24, topTrailingRadius: 24))
        .ignoresSafeArea(edges: .vertical)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1)
                .ignoresSafeArea(edges: .vertical)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("Categories")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.08), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
    }

    private func row(for category: Category, isSelected: Bool) -> some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: category.thumbnail)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    Circle().fill(Color.white.opacity(0.12))
                }
            }
            .frame(width: 42, height: 42)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(
                    isSelected ? AppThemeService.accent : Color.white.opacity(0.18),
                    lineWidth: isSelected ? 1.5 : 0.5
                )
            )

            Text(category.name)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .background(
            ZStack(alignment: .trailing) {
                AsyncImage(url: URL(string: category.thumbnail)) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        Color.white.opacity(0.04)
                    }
                }
                .clipped()

                LinearGradient(
                    colors: [
                        .black.opacity(0.85),
                        .black.opacity(0.55),
                        .black.opacity(0.25)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isSelected ? AppThemeService.accent : Color.white.opacity(0.07),
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}

struct WallpaperDetailView_Previews: PreviewProvider {
    static var previews: some View {
        WallpaperDetailView(categoryId: 2, wallpaperId: 3)
    }
}
