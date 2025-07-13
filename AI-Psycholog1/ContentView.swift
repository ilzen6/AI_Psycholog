//
//  ContentView.swift - ОКОНЧАТЕЛЬНОЕ ИСПРАВЛЕНИЕ Publishing changes
//  AI_Psycholog
//
//  КРИТИЧНО: Полностью убираем все Timer и используем Task + async/await
//

import SwiftUI
import WebKit

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isAuthenticated = false
    @State private var showSplash = true
    @State private var showDisclaimer = false
    @State private var showOnboarding = false
    @StateObject private var webViewModel = WebViewModel()
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("hasAcceptedDisclaimer") private var hasAcceptedDisclaimer = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView(showSplash: $showSplash)
                    .transition(.opacity)
            } else if !hasAcceptedDisclaimer && showDisclaimer {
                DisclaimerView(
                    isPresented: $showDisclaimer,
                    onAccepted: {
                        print("📱 ContentView: Дисклеймер принят, переходим к онбордингу")
                        Task {
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 сек
                            showDisclaimer = false
                            if !hasSeenOnboarding {
                                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 сек
                                showOnboarding = true
                            }
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom),
                    removal: .move(edge: .bottom)
                ))
            } else if !hasSeenOnboarding && showOnboarding {
                OnboardingView(
                    isPresented: $showOnboarding,
                    onCompleted: {
                        print("📱 ContentView: Онбординг завершен")
                        Task {
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 сек
                            showOnboarding = false
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            } else if !isAuthenticated {
                LoginView(isAuthenticated: $isAuthenticated)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else {
                TabView(selection: $selectedTab) {
                    ChatView(webViewModel: webViewModel)
                        .tabItem {
                            Label("Чат", systemImage: "message.fill")
                        }
                        .tag(0)
                    
                    MoodJournalView()
                        .tabItem {
                            Label("Настроение", systemImage: "face.smiling")
                        }
                        .tag(1)
                    
                    ExercisesView()
                        .tabItem {
                            Label("Упражнения", systemImage: "leaf.fill")
                        }
                        .tag(2)
                    
                    ProfileView(webViewModel: webViewModel)
                        .tabItem {
                            Label("Профиль", systemImage: "person.fill")
                        }
                        .tag(3)
                    
                    PaymentView()
                        .tabItem {
                            Label("Оплата", systemImage: "creditcard.fill")
                        }
                        .tag(4)
                }
                .accentColor(Color(hex: "889E8C"))
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .animation(.easeInOut(duration: 0.3), value: showOnboarding)
        .animation(.easeInOut(duration: 0.3), value: showDisclaimer)
        .animation(.easeInOut(duration: 0.3), value: isAuthenticated)
        .task {
            // КРИТИЧНО: Используем Task вместо onAppear для async операций
            await setupInitialState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidLogout)) { _ in
            print("📱 ContentView: ⚠️ ПОЛУЧЕНО УВЕДОМЛЕНИЕ О ВЫХОДЕ ИЗ АККАУНТА")
            
            Task {
                await MainActor.run {
                    print("📱 ContentView: Было: isAuthenticated = \(isAuthenticated)")
                    
                    // КРИТИЧНО: Переключаем на экран авторизации
                    isAuthenticated = false
                    
                    print("📱 ContentView: Стало: isAuthenticated = \(isAuthenticated)")
                    print("📱 ContentView: ✅ ПЕРЕХОД К ЭКРАНУ АВТОРИЗАЦИИ")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidLogin)) { _ in
            print("📱 ContentView: Получено уведомление о входе в аккаунт")
            
            Task {
                await MainActor.run {
                    print("📱 ContentView: Устанавливаем isAuthenticated = true")
                    isAuthenticated = true
                }
            }
        }
    }
    
    // КРИТИЧНО: Async функция для настройки начального состояния
    private func setupInitialState() async {
        print("📱 ContentView: Настройка начального состояния")
        print("   hasAcceptedDisclaimer: \(hasAcceptedDisclaimer)")
        print("   hasSeenOnboarding: \(hasSeenOnboarding)")
        
        applyThemeOnLaunch()
        
        // Ждем анимацию splash screen
        try? await Task.sleep(nanoseconds: 4_000_000_000) // 4 секунды
        
        print("📱 ContentView: Завершаем splash screen")
        showSplash = false
        
        // Небольшая задержка между переходами
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 сек
        
        // Определяем следующий экран
        if !hasAcceptedDisclaimer {
            print("📱 ContentView: Показываем дисклеймер")
            showDisclaimer = true
        } else if !hasSeenOnboarding {
            print("📱 ContentView: Показываем онбординг")
            showOnboarding = true
        } else {
            print("📱 ContentView: Переходим к авторизации")
            // Автоматически покажется LoginView
        }
    }
    
    private func applyThemeOnLaunch() {
        // Применяем сохраненную тему при запуске
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            }
        }
    }
}
