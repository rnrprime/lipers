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

    var body: some Scene {
        WindowGroup {
            ZStack {
                if splashFinished {
                    ContentView()
                        .transition(.opacity)
                } else {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            splashFinished = true
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
    }
}
