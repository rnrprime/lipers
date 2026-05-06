//
//  ContentView.swift
//  LipersFree
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RootTabViewModel()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            NavigationStack {
                ExploreView()
            }
            .tabItem {
                Label(AppTab.explore.title, systemImage: AppTab.explore.systemImage)
            }
            .tag(AppTab.explore)

            NavigationStack {
                MakerView()
            }
            .tabItem {
                Label(AppTab.maker.title, systemImage: AppTab.maker.systemImage)
            }
            .tag(AppTab.maker)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(AppTab.settings.title, systemImage: AppTab.settings.systemImage)
            }
            .tag(AppTab.settings)
        }
        .tint(AppThemeService.accent)
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
