//
//  OnboardingView.swift
//  LipersFree
//

import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var step: Int = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Bring Your Screen\nto Life",
            subtitle: "Stunning live wallpapers that move with every tap.",
            mockup: .welcome,
            bullets: []
        ),
        OnboardingPage(
            title: "Endless Live\nWallpapers",
            subtitle: "Curated from every category, updated regularly.",
            mockup: .browse,
            bullets: [
                "Thousands of live wallpapers",
                "Sorted by mood and category",
                "New additions every week"
            ]
        ),
        OnboardingPage(
            title: "Make Your Own",
            subtitle: "Turn any video into a Live Photo wallpaper.",
            mockup: .make,
            bullets: [
                "Pick any video from your library",
                "Choose the perfect frame",
                "Save in one tap"
            ]
        )
    ]

    private var totalSteps: Int { pages.count + 1 } // pages + paywall

    var body: some View {
        ZStack {
            AppThemeService.screenBackground.ignoresSafeArea()
            ambientBackdrop

            if step < pages.count {
                onboardingPager
                    .transition(.opacity)
            } else {
                PaywallView(
                    onSubscribe: { onComplete() },
                    onMaybeLater: { onComplete() }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: step)
    }

    // MARK: - Ambient backdrop (subtle, restrained)

    private var ambientBackdrop: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(AppThemeService.accent.opacity(0.18))
                    .frame(width: 360, height: 360)
                    .blur(radius: 90)
                    .offset(x: -geo.size.width * 0.35, y: -geo.size.height * 0.25)

                Circle()
                    .fill(AppThemeService.accentLight.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 100)
                    .offset(x: geo.size.width * 0.35, y: geo.size.height * 0.3)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Pager

    private var onboardingPager: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.top, 8)

            TabView(selection: $step) {
                ForEach(0..<pages.count, id: \.self) { index in
                    pageBody(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            bottomBar
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button("Skip") {
                withAnimation { step = pages.count } // jump to paywall
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white.opacity(0.55))
        }
        .frame(height: 24)
        .padding(.horizontal, 24)
    }

    private func pageBody(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)

            mockup(for: page.mockup)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 12)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .tracking(-0.3)

                Text(page.subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 24)
            }
            .padding(.horizontal, 24)

            if !page.bullets.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(page.bullets, id: \.self) { bullet in
                        bulletRow(bullet)
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 32)
            }

            Spacer(minLength: 16)
        }
    }

    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppThemeService.accent.opacity(0.18))
                    .frame(width: 22, height: 22)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(AppThemeService.accent)
            }
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
        }
    }

    @ViewBuilder
    private func mockup(for kind: OnboardingMockup) -> some View {
        switch kind {
        case .welcome: WelcomeMockup()
        case .browse:  BrowseMockup()
        case .make:    MakeMockup()
        }
    }

    // MARK: - Bottom controls

    private var bottomBar: some View {
        VStack(spacing: 22) {
            pageIndicator
            ctaButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }

    private var pageIndicator: some View {
        HStack(spacing: 7) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == step ? AppThemeService.accent : Color.white.opacity(0.18))
                    .frame(width: index == step ? 22 : 7, height: 7)
                    .animation(.easeInOut(duration: 0.25), value: step)
            }
        }
    }

    private var ctaButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.4)) {
                step += 1
            }
        } label: {
            Text(step == pages.count - 1 ? "Get Started" : "Continue")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [AppThemeService.accent, AppThemeService.accentLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .shadow(color: AppThemeService.accent.opacity(0.45), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Page model

private struct OnboardingPage {
    let title: String
    let subtitle: String
    let mockup: OnboardingMockup
    let bullets: [String]
}

private enum OnboardingMockup {
    case welcome, browse, make
}

// MARK: - Reusable phone frame

private struct PhoneFrame<Content: View>: View {
    let width: CGFloat
    let height: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Color(hex: "0A0C13"))
                .frame(width: width + 12, height: height + 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.6), radius: 28, y: 16)

            content()
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

            Capsule()
                .fill(Color.black)
                .frame(width: 78, height: 22)
                .offset(y: -(height / 2) + 16)
        }
    }
}

// MARK: - Page 1: Welcome — phone showing a live wallpaper preview

private struct WelcomeMockup: View {
    var body: some View {
        PhoneFrame(width: 200, height: 380) {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "9B5CF6"),
                        Color(hex: "EC4899"),
                        Color(hex: "1E1B4B")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 150, height: 150)
                    .blur(radius: 30)
                    .offset(x: -40, y: -50)

                Circle()
                    .fill(AppThemeService.accent.opacity(0.4))
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)
                    .offset(x: 60, y: 80)

                VStack {
                    HStack {
                        liveBadge
                        Spacer()
                    }
                    .padding(.top, 50)
                    .padding(.horizontal, 14)
                    Spacer()
                }
            }
        }
    }

    private var liveBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "livephoto")
                .font(.system(size: 9, weight: .semibold))
            Text("LIVE")
                .font(.system(size: 9, weight: .heavy))
                .tracking(0.5)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5))
    }
}

// MARK: - Page 2: Browse — phone showing the Explore grid

private struct BrowseMockup: View {
    private let cards: [(top: Color, bottom: Color)] = [
        (Color(hex: "EC4899"), Color(hex: "8B5CF6")),
        (Color(hex: "06B6D4"), Color(hex: "3B82F6")),
        (Color(hex: "F59E0B"), Color(hex: "EF4444")),
        (Color(hex: "10B981"), Color(hex: "06B6D4")),
        (Color(hex: "9B5CF6"), Color(hex: "C084FC")),
        (Color(hex: "1F2937"), Color(hex: "374151"))
    ]

    var body: some View {
        PhoneFrame(width: 200, height: 380) {
            ZStack {
                Color(hex: "141824")

                VStack(spacing: 10) {
                    Spacer().frame(height: 30)

                    Text("Live Wallpapers")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 6) {
                        chip("All", selected: true)
                        chip("Nature", selected: false)
                        chip("Anime", selected: false)
                    }
                    .padding(.horizontal, 12)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 6),
                                        GridItem(.flexible(), spacing: 6)],
                              spacing: 6) {
                        ForEach(0..<cards.count, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [cards[i].top, cards[i].bottom],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(height: 92)
                                .overlay(alignment: .topTrailing) {
                                    if i == 0 {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 7, weight: .bold))
                                            .foregroundStyle(AppThemeService.premiumGold)
                                            .padding(4)
                                            .background(.black.opacity(0.4), in: Circle())
                                            .padding(5)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 10)

                    Spacer()
                }
            }
        }
    }

    private func chip(_ name: String, selected: Bool) -> some View {
        Text(name)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                selected ? AppThemeService.accent.opacity(0.3) : Color.white.opacity(0.06),
                in: Capsule()
            )
            .overlay(
                Capsule().stroke(
                    selected ? AppThemeService.accent.opacity(0.7) : Color.white.opacity(0.1),
                    lineWidth: 0.5
                )
            )
    }
}

// MARK: - Page 3: Make — phone showing the Maker preview

private struct MakeMockup: View {
    var body: some View {
        PhoneFrame(width: 200, height: 380) {
            ZStack {
                Color(hex: "141824")

                VStack(spacing: 12) {
                    Spacer().frame(height: 30)

                    Text("Live Photo Maker")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)

                    // Video preview area
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color(hex: "8B5CF6"), Color(hex: "EC4899")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))

                        Image(systemName: "play.fill")
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 168, height: 200)
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)

                    // Filmstrip
                    HStack(spacing: 2) {
                        ForEach(0..<10, id: \.self) { i in
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [
                                        Color(hex: "8B5CF6").opacity(0.7),
                                        Color(hex: "EC4899").opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(height: 24)
                                .opacity(0.5 + Double(i) * 0.05)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(AppThemeService.accent, lineWidth: 1.2)
                    )
                    .padding(.horizontal, 14)

                    // Aspect chips
                    HStack(spacing: 6) {
                        ForEach(["9:16", "1:1", "16:9"], id: \.self) { name in
                            Text(name)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    name == "9:16"
                                        ? AppThemeService.accent.opacity(0.3)
                                        : Color.white.opacity(0.06),
                                    in: Capsule()
                                )
                        }
                    }

                    Spacer()
                }
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
