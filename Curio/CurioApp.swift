//
//  CurioApp.swift
//  Curio
//
//  Created by Manik on 5/1/25.
//

import SwiftUI
import SwiftData

@main
struct CurioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupAppearance()
                }
        }
        .modelContainer(for: BookmarkArticle.self)
    }
    
    private func setupAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
    }
}
