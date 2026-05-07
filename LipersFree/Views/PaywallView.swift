//
//  PaywallView.swift
//  LipersFree
//

import SwiftUI

enum PaywallPlan: String, CaseIterable, Identifiable {
    case yearly, monthly
    var id: String { rawValue }
}

struct PaywallView: View {
    let onSubscribe: () -> Void
    let onMaybeLater: () -> Void

    @State private var selectedPlan: PaywallPlan = .yearly

    var body: some View {
        ZStack {
            AppThemeService.screenBackground.ignoresSafeArea()
            ambientGlow

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        hero
                        featuresList
                        planSelector
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }

                bottomBar
            }
        }
    }

    // MARK: - Backdrop

    private var ambientGlow: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(AppThemeService.premiumGold.opacity(0.15))
                    .frame(width: 360, height: 360)
                    .blur(radius: 90)
                    .offset(x: 0, y: -geo.size.height * 0.35)

                Circle()
                    .fill(AppThemeService.accent.opacity(0.2))
                    .frame(width: 320, height: 320)
                    .blur(radius: 100)
                    .offset(x: -geo.size.width * 0.25, y: geo.size.height * 0.15)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Top bar (close button)

    private var topBar: some View {
        HStack {
            Button(action: onMaybeLater) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.08), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            Spacer()
            Button(action: {}) {
                Text("Restore")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppThemeService.premiumGold.opacity(0.15))
                    .frame(width: 96, height: 96)
                    .blur(radius: 20)

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppThemeService.premiumGold,
                                    Color(hex: "F97316")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: AppThemeService.premiumGold.opacity(0.5), radius: 12, y: 4)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(.white)
                }
            }

            VStack(spacing: 6) {
                Text("Lipers Pro")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(-0.3)

                Text("Unlock everything. No limits.")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Features

    private var featuresList: some View {
        VStack(spacing: 14) {
            featureRow(icon: "sparkles", title: "Access all premium wallpapers")
            featureRow(icon: "infinity",  title: "Unlimited downloads")
            featureRow(icon: "wand.and.stars", title: "Full Live Photo Maker")
            featureRow(icon: "rectangle.stack.fill", title: "No ads, ever")
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            AppThemeService.surface,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func featureRow(icon: String, title: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppThemeService.accent.opacity(0.18))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppThemeService.accent)
            }
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
            Spacer()
        }
    }

    // MARK: - Plan selector

    private var planSelector: some View {
        VStack(spacing: 10) {
            planCard(
                plan: .yearly,
                title: "Yearly",
                price: "$29.99",
                subtitle: "$2.50 / month",
                badge: "SAVE 50%"
            )
            planCard(
                plan: .monthly,
                title: "Monthly",
                price: "$4.99",
                subtitle: "Billed monthly",
                badge: nil
            )
        }
    }

    private func planCard(plan: PaywallPlan,
                          title: String,
                          price: String,
                          subtitle: String,
                          badge: String?) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { selectedPlan = plan }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? AppThemeService.accent : Color.white.opacity(0.25),
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(AppThemeService.accent)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .black))
                                .tracking(0.5)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(
                                        colors: [AppThemeService.premiumGold, Color(hex: "F97316")],
                                        startPoint: .leading, endPoint: .trailing
                                    ),
                                    in: Capsule()
                                )
                        }
                    }
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                Text(price)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                isSelected ? AppThemeService.accent.opacity(0.10) : AppThemeService.surface,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? AppThemeService.accent : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            Button(action: onSubscribe) {
                Text("Continue")
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

            Button(action: onMaybeLater) {
                Text("Maybe later")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .buttonStyle(.plain)

            HStack(spacing: 18) {
                Button("Terms") {}
                    .foregroundStyle(.white.opacity(0.4))
                Text("•").foregroundStyle(.white.opacity(0.25))
                Button("Privacy") {}
                    .foregroundStyle(.white.opacity(0.4))
            }
            .font(.system(size: 11, weight: .medium))
            .padding(.top, 2)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

#Preview {
    PaywallView(onSubscribe: {}, onMaybeLater: {})
}
