//
//  LipersFreeApp.swift
//  LipersFree
//
//  Created by Rashed Nizam on 31/3/26.
//

import SwiftUI

@main
struct LipersFreeApp: App {
    @State private var splashFinished = false
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !splashFinished {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            splashFinished = true
                        }
                    }
                    .transition(.opacity)
                } else if !hasOnboarded {
                    OnboardingView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            hasOnboarded = true
                        }
                    }
                    .transition(.opacity)
                } else {
                    ContentView()
                        .transition(.opacity)
                }
            }
        }
    }
}
