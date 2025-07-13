//
//  SplashView.swift - ИСПРАВЛЕННЫЙ
//  AI_Psycholog
//
//  КРИТИЧНО: Простая анимация без callback
//

import SwiftUI

struct SplashView: View {
    @State private var brainScale: CGFloat = 1.0
    @State private var showText = false
    @State private var textOpacity: Double = 0.0
    @State private var textOffset: CGFloat = 50
    @Binding var showSplash: Bool
    
    var body: some View {
        ZStack {
            // Фон с градиентом
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "A5BDA9"),
                    Color(hex: "889E8C")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Анимированная иконка мозга
                Image(systemName: "brain")
                    .font(.system(size: 120, weight: .light))
                    .foregroundColor(.white)
                    .scaleEffect(brainScale)
                
                Spacer()
                
                // Анимированный текст
                if showText {
                    VStack(spacing: 16) {
                        Text("поговорите с собой,")
                            .font(.title2)
                            .fontWeight(.light)
                            .foregroundColor(.white)
                            .opacity(textOpacity)
                            .offset(y: textOffset)
                        
                        Text("с помощью нас")
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .opacity(textOpacity)
                            .offset(y: textOffset)
                    }
                    .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        print("📱 SplashView: Запускаем анимации")
        
        // Запускаем анимацию мозга сразу
        withAnimation(
            Animation
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
        ) {
            brainScale = 1.2
        }
        
        // Показываем текст через 2 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.8)) {
                showText = true
                textOpacity = 1.0
                textOffset = 0
            }
        }
        
        print("📱 SplashView: Анимации запущены, ContentView контролирует время")
    }
}
