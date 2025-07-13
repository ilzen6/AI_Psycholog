//
//  LoginView.swift - УБРАНА биометрическая аутентификация
//  AI_Psycholog
//
//  УПРОЩЕНО: Только логин/пароль, никакой биометрии
//

import SwiftUI

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var username = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingRegistration = false
    @AppStorage("lastUsername") private var lastUsername = ""
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        ZStack {
            Color(hex: "A5BDA9")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Верхняя часть с аватаром
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text("Аватар")
                                .foregroundColor(Color(hex: "889E8C"))
                                .font(.system(size: 14))
                        )
                    
                    Image(systemName: "brain")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                    
                    Text("AI-консультант всегда\nрядом, когда он вам нужен")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Форма входа
                VStack(spacing: 16) {
                    // Поле логина
                    TextField("Введите Ваш логин", text: $username)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .accentColor(Color(hex: "889E8C"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Поле пароля
                    SecureField("Введите пароль", text: $password)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .accentColor(Color(hex: "889E8C"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Кнопки
                    VStack(spacing: 12) {
                        Button(action: login) {
                            Text("Войти")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color(hex: "7A9A7E"))
                                .cornerRadius(8)
                        }
                        
                        Button(action: showRegistration) {
                            Text("Регистрация")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingRegistration) {
            RegistrationView(isPresented: $showingRegistration)
        }
        .onAppear {
            // Заполняем последний использованный логин
            if !lastUsername.isEmpty {
                username = lastUsername
            }
        }
        .environment(\.colorScheme, .light)
    }
    
    private func showRegistration() {
        showingRegistration = true
    }
    
    func login() {
        guard validateInput() else { return }
        
        APIManager.shared.login(username: username, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    KeychainManager.shared.saveCredentials(
                        username: self.username,
                        password: self.password,
                        token: response.token
                    )
                    
                    // Сохраняем логин для автозаполнения
                    self.lastUsername = self.username
                    
                    // Уведомляем ChatView о необходимости автологина на сайт
                    NotificationCenter.default.post(name: .userDidLogin, object: nil)
                    
                    self.isAuthenticated = true
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
    
    func validateInput() -> Bool {
        let loginRegex = "^[a-zA-Z]{1}\\w{7,19}$"
        let loginPredicate = NSPredicate(format: "SELF MATCHES %@", loginRegex)
        
        guard loginPredicate.evaluate(with: username) else {
            errorMessage = "Логин должен содержать 8-20 символов"
            showingError = true
            return false
        }
        
        let passwordRegex = "^\\w{8,20}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        
        guard passwordPredicate.evaluate(with: password) else {
            errorMessage = "Пароль должен содержать 8-20 символов"
            showingError = true
            return false
        }
        
        return true
    }
}
