//
//  RegistrationView.swift
//  AI_Psycholog
//
//  Created by Илья Зенькович on 23.06.2025.
//

import SwiftUI

struct RegistrationView: View {
    @Binding var isPresented: Bool
    @State private var fullName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var login = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "A5BDA9")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Аватар
                        Circle()
                            .fill(Color.white)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text("Аватар")
                                    .foregroundColor(Color(hex: "889E8C"))
                                    .font(.system(size: 14))
                            )
                            .padding(.top, 40)
                        
                        // Форма регистрации
                        VStack(spacing: 16) {
                            // ФИО
                            TextField("ФИО", text: $fullName)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                            
                            // Телефон
                            TextField("Номер телефона", text: $phone)
                                .keyboardType(.phonePad)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                            
                            // Email
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                            
                            // Логин
                            TextField("Логин", text: $login)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                            
                            // Пароль
                            SecureField("Пароль", text: $password)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                            
                            // Подтверждение пароля
                            SecureField("Подтверждение пароля", text: $confirmPassword)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 40)
                        
                        // Кнопка регистрации
                        Button(action: register) {
                            Text("Зарегистрироваться")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color(hex: "7A9A7E"))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarItems(
                leading: Button("Отмена") {
                    isPresented = false
                }
                .foregroundColor(.white)
            )
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    func register() {
        // Валидация
        guard validateInput() else { return }
        
        // API запрос
        let registrationData = [
            "login": login,
            "password": password,
            "FIO": fullName,
            "phone": phone,
            "email": email
        ]
        
        APIManager.shared.register(data: registrationData) { result in
            switch result {
            case .success:
                isPresented = false
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    func validateInput() -> Bool {
        // Проверка ФИО
        let fioRegex = "^[А-Я]{1}[а-яА-Я\\s\\-]{0,150}$"
        let fioPredicate = NSPredicate(format: "SELF MATCHES %@", fioRegex)
        guard fioPredicate.evaluate(with: fullName) else {
            errorMessage = "ФИО должно начинаться с заглавной буквы"
            showingError = true
            return false
        }
        
        // Проверка телефона
        let phoneRegex = "^(\\+7|8)\\d{10}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        guard phonePredicate.evaluate(with: phone) else {
            errorMessage = "Неверный формат телефона"
            showingError = true
            return false
        }
        
        // Проверка email
        let emailRegex = "^[a-zA-Z]{1}[0-9a-zA-Z-_!\\#\\$%&'\\*\\+\\-\\/=?\\^`\\{|\\}~\\.]+\\@\\w+\\.(com|ru)$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            errorMessage = "Неверный формат email"
            showingError = true
            return false
        }
        
        // Проверка логина
        let loginRegex = "^[a-zA-Z]{1}\\w{7,19}$"
        let loginPredicate = NSPredicate(format: "SELF MATCHES %@", loginRegex)
        guard loginPredicate.evaluate(with: login) else {
            errorMessage = "Логин должен содержать 8-20 символов и начинаться с буквы"
            showingError = true
            return false
        }
        
        // Проверка пароля
        let passwordRegex = "^\\w{8,20}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        guard passwordPredicate.evaluate(with: password) else {
            errorMessage = "Пароль должен содержать 8-20 символов"
            showingError = true
            return false
        }
        
        // Проверка совпадения паролей
        guard password == confirmPassword else {
            errorMessage = "Пароли не совпадают"
            showingError = true
            return false
        }
        
        return true
    }
}
