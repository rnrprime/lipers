//
//  SettingsView.swift
//  LipersFree
//

import SwiftUI
import StoreKit
import UIKit

private enum WallpaperTarget: String, CaseIterable {
    case home = "Home"
    case lock = "Lock"
    case both = "Both"
}

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @State private var wallpaperTarget: WallpaperTarget = .both
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false

    private let appStoreURL = URL(string: "https://apps.apple.com/app/id1181075088")!
    private let writeReviewURL = URL(string: "https://apps.apple.com/app/id1181075088?action=write-review")!

    var body: some View {
        ZStack {
            AppThemeService.screenBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    goProBanner
                    accountSection
                    preferencesSection
                    aboutSection
                    appSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(activityItems: shareItems)
        }
    }

    // MARK: - Header

    private var header: some View {
        Text("Settings")
            .font(.system(size: 30, weight: .bold))
            .foregroundStyle(.white)
            .padding(.bottom, 4)
    }

    // MARK: - Go Pro Banner

    private var goProBanner: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [Color(hex: "6D28D9"), AppThemeService.accent, AppThemeService.accentLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 160, height: 160)
                .offset(x: 60, y: -60)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 100, height: 100)
                .offset(x: 30, y: 40)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppThemeService.premiumGold)
                            Text("LIPER PRO")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(AppThemeService.premiumGold)
                                .tracking(1)
                        }

                        Text("Unlock All\nWallpapers")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .lineSpacing(2)
                    }

                    Spacer()
                }

                Text("Access thousands of premium live wallpapers with no limits.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)

                Button {} label: {
                    Text("Go Pro")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppThemeService.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .frame(height: 220)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        section(title: "Account") {
            row(
                icon: "arrow.counterclockwise",
                iconColor: Color(hex: "3B82F6"),
                title: "Restore Purchases"
            )
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        section(title: "Preferences") {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    iconCell(systemName: "iphone", color: Color(hex: "10B981"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Set Wallpaper To")
                            .font(.body)
                            .foregroundStyle(.white)
                        Text("Choose where wallpapers are applied")
                            .font(.caption)
                            .foregroundStyle(AppThemeService.textSecondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

                Picker("", selection: $wallpaperTarget) {
                    ForEach(WallpaperTarget.allCases, id: \.self) { target in
                        Text(target.rawValue).tag(target)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        section(title: "About") {
            row(
                icon: "star.bubble.fill",
                iconColor: Color(hex: "F59E0B"),
                title: "Leave an In-App Review",
                action: requestInAppReview
            )
            divider
            row(
                icon: "star.fill",
                iconColor: Color(hex: "F59E0B"),
                title: "Rate on App Store",
                action: openAppStoreReviewPage
            )
            divider
            row(
                icon: "square.and.arrow.up",
                iconColor: AppThemeService.accent,
                title: "Share App",
                action: shareApp
            )
            divider
            row(icon: "lock.shield.fill", iconColor: Color(hex: "10B981"), title: "Privacy Policy")
            divider
            row(icon: "doc.text.fill", iconColor: Color(hex: "3B82F6"), title: "Terms of Use")
        }
    }

    // MARK: - App Section

    private var appSection: some View {
        section(title: "App") {
            HStack(spacing: 14) {
                iconCell(systemName: "info.circle.fill", color: Color.gray.opacity(0.6))

                Text("Version")
                    .font(.body)
                    .foregroundStyle(.white)

                Spacer()

                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .font(.body)
                    .foregroundStyle(AppThemeService.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Reusable Components

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppThemeService.textSecondary)
                .tracking(0.6)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(AppThemeService.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private func row(
        icon: String,
        iconColor: Color,
        title: String,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconCell(systemName: icon, color: iconColor)

                Text(title)
                    .font(.body)
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppThemeService.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func iconCell(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 0.5)
            .padding(.leading, 60)
    }

    private func requestInAppReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }

        SKStoreReviewController.requestReview(in: scene)
    }

    private func openAppStoreReviewPage() {
        openURL(writeReviewURL)
    }

    private func shareApp() {
        shareItems = [
            "Check out Lipers Lite Live Wallpapers on the App Store.",
            appStoreURL
        ]
        showShareSheet = true
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
        .preferredColorScheme(.dark)
    }
}

private struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
