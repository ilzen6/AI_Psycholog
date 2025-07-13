//
//  AI_PsychologApp.swift
//  AI_Psycholog
//
//  Created by Илья Зенькович on 21.06.2025.
//

import SwiftUI

@main
struct AI_PsychologApp: App {
    init() {
        // Настройка внешнего вида
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    func setupAppearance() {
        // Настройка навигационной панели
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor(Color(hex: "889E8C"))
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Настройка TabBar
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
        UITabBar.appearance().tintColor = UIColor(Color(hex: "889E8C"))
    }
}
