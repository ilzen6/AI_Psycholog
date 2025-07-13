//
//  OnboardingView.swift - ОКОНЧАТЕЛЬНОЕ ИСПРАВЛЕНИЕ
//  AI_Psycholog
//
//  КРИТИЧНО: Простая структура без сложной логики
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    let onCompleted: () -> Void
    
    let pages = OnboardingPage.allPages
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack {
                ForEach(0..<pages.count, id: \.self) { index in
                    Rectangle()
                        .fill(index <= currentPage ? Color(hex: "889E8C") : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Page content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            // Navigation buttons
            VStack(spacing: 20) {
                if currentPage < pages.count - 1 {
                    Button(action: nextPage) {
                        Text("Далее")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "889E8C"))
                            .cornerRadius(12)
                    }
                    
                    Button(action: skip) {
                        Text("Пропустить")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button(action: complete) {
                        Text("Начать использование")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "889E8C"))
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private func nextPage() {
        withAnimation {
            if currentPage < pages.count - 1 {
                currentPage += 1
            }
        }
    }
    
    private func skip() {
        complete()
    }
    
    private func complete() {
        print("📱 OnboardingView: Завершаем онбординг")
        hasSeenOnboarding = true
        onCompleted()
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon/Image
            ZStack {
                Circle()
                    .fill(page.backgroundColor)
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(spacing: 20) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Models

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let backgroundColor: Color
    
    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            icon: "brain",
            title: "Добро пожаловать в AI-Психолог",
            description: "Персональная поддержка с помощью искусственного интеллекта. Получите эмоциональную помощь и рекомендации 24/7.",
            backgroundColor: Color(hex: "889E8C")
        ),
        
        OnboardingPage(
            icon: "shield.checkerboard",
            title: "Безопасность и конфиденциальность",
            description: "Ваши данные защищены. Все беседы конфиденциальны и используются только для предоставления поддержки.",
            backgroundColor: .blue
        ),
        
        OnboardingPage(
            icon: "face.smiling",
            title: "Отслеживайте настроение",
            description: "Ведите журнал эмоций, отслеживайте изменения настроения и наблюдайте за своим прогрессом.",
            backgroundColor: .green
        ),
        
        OnboardingPage(
            icon: "leaf",
            title: "Упражнения для релаксации",
            description: "Дыхательные техники, медитация и другие упражнения для снижения стресса и улучшения самочувствия.",
            backgroundColor: .orange
        )
    ]
}
