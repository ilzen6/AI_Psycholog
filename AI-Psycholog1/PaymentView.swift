//
//  PaymentView.swift - исправленная версия без ошибок
//  AI_Psycholog1
//
//  Mock In-App Purchase для тестирования
//

import SwiftUI

struct PaymentView: View {
    @StateObject private var paymentManager = MockPaymentManager.shared
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var profile = UserProfile()
    @State private var localSessionBalance = 0
    @State private var totalSessionBalance: Int = 0
    @State private var showingDemo = true
    
    // Анимация
    @State private var animatedBalance = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Заголовок и баланс
                headerSection
                
                // Основной контент
                if paymentManager.isLoading {
                    loadingSection
                } else if paymentManager.products.isEmpty {
                    errorSection
                } else {
                    productListSection
                }
                
                Spacer()
                
                // Футер с дополнительными опциями
                footerSection
            }
            .navigationTitle("Пополнение баланса")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(UIColor.systemGroupedBackground))
        }
        .task {
            await loadData()
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SessionBalanceUpdated"))) { _ in
            loadSessionBalance()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Баланс пользователя
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "star.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "889E8C"))
                    
                    Text("Доступно сессий")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Text("\(animatedBalance)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "889E8C"))
                    .animation(.easeOut(duration: 0.8), value: animatedBalance)
                
                Text("Выберите пакет для пополнения")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
            )
            .padding(.horizontal)
            
            // Режим разработки
            if showingDemo {
                HStack {
                    Image(systemName: "hammer.circle.fill")
                        .foregroundColor(.orange)
                    Text("Режим разработки")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Button("Скрыть") {
                        withAnimation {
                            showingDemo = false
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    private var loadingSection: some View {
        VStack(spacing: 30) {
            // Красивый индикатор загрузки
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "889E8C")))
                    .scaleEffect(1.5)
                
                Text("Загрузка продуктов...")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Подготавливаем лучшие предложения для вас")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxHeight: .infinity)
        }
        .padding()
    }
    
    private var errorSection: some View {
        VStack(spacing: 30) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                Text("Продукты недоступны")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Проверьте подключение к интернету и попробуйте снова")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                Task {
                    await loadData()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Обновить")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "889E8C"))
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
    
    private var productListSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(paymentManager.products) { product in
                    EnhancedProductCard(
                        product: product,
                        isPurchasing: paymentManager.isLoading,
                        currentBalance: totalSessionBalance,
                        action: {
                            Task {
                                await purchaseProduct(product)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100) // Отступ для футера
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            // Кнопка восстановления покупок
            Button(action: {
                Task {
                    await restorePurchases()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise.circle")
                    Text("Восстановить покупки")
                }
                .font(.subheadline)
                .foregroundColor(Color(hex: "889E8C"))
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "889E8C"), lineWidth: 1)
                )
            }
            .disabled(paymentManager.isLoading)
            
            // Информация о разработке
            Text("🔧 Все покупки в режиме разработки бесплатны")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Methods
    
    private func loadData() async {
        await paymentManager.loadProducts()
        loadSessionBalance()
        loadProfile()
    }
    
    private func loadSessionBalance() {
        localSessionBalance = UserDefaults.standard.integer(forKey: "localSessionBalance")
        updateTotalBalance()
    }
    
    private func loadProfile() {
        APIManager.shared.getProfile { result in
            switch result {
            case .success(let profileData):
                self.profile = profileData
                self.updateTotalBalance()
            case .failure:
                // Используем только локальный баланс если API недоступен
                self.updateTotalBalance()
            }
        }
    }
    
    private func updateTotalBalance() {
        let newTotal = profile.sessionBalance + localSessionBalance
        
        // Анимируем изменение баланса
        if newTotal != totalSessionBalance {
            withAnimation(.easeOut(duration: 0.8)) {
                totalSessionBalance = newTotal
                animatedBalance = newTotal
            }
        } else {
            totalSessionBalance = newTotal
            animatedBalance = newTotal
        }
    }
    
    private func purchaseProduct(_ product: MockProduct) async {
        let success = await paymentManager.purchase(product)
        
        if success {
            // Добавляем анимацию успешной покупки
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                loadSessionBalance()
            }
            
            alertTitle = "Покупка успешна! 🎉"
            alertMessage = "Демо-покупка: +\(product.sessionCount) сессий добавлено в ваш аккаунт"
            showingAlert = true
        } else if !paymentManager.errorMessage.isEmpty {
            alertTitle = "Ошибка покупки"
            alertMessage = paymentManager.errorMessage
            showingAlert = true
        }
    }
    
    private func restorePurchases() async {
        await paymentManager.restorePurchases()
        loadSessionBalance()
        
        alertTitle = "Покупки восстановлены"
        alertMessage = "Все предыдущие покупки успешно восстановлены (демо-режим)"
        showingAlert = true
    }
}

struct EnhancedProductCard: View {
    let product: MockProduct
    let isPurchasing: Bool
    let currentBalance: Int
    let action: () -> Void
    
    private var pricePerSession: Int {
        Int(product.price) / product.sessionCount
    }
    
    private var savings: String? {
        let basePrice = 50 // Базовая цена за сессию
        let currentPrice = pricePerSession
        let savingsPercent = ((basePrice - currentPrice) * 100) / basePrice
        
        return savingsPercent > 0 ? "Экономия \(savingsPercent)%" : nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Топ карточки с бейджем популярности
            if product.isPopular || savings != nil {
                HStack {
                    if product.isPopular {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text("Популярный выбор")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(12)
                    }
                    
                    if let savings = savings {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.caption2)
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            
            // Основной контент карточки
            HStack(spacing: 16) {
                // Левая часть - иконка и информация
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        // Иконка с сессиями
                        ZStack {
                            Circle()
                                .fill(Color(hex: "889E8C").opacity(0.1))
                                .frame(width: 44, height: 44)
                            
                            Text("\(product.sessionCount)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "889E8C"))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.displayName)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(product.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Дополнительная информация
                    HStack(spacing: 12) {
                        Label("\(pricePerSession) ₽/сессия", systemImage: "tag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label("Итого: \(currentBalance + product.sessionCount)", systemImage: "sum")
                            .font(.caption)
                            .foregroundColor(Color(hex: "889E8C"))
                    }
                }
                
                Spacer()
                
                // Правая часть - цена и кнопка
                VStack(alignment: .trailing, spacing: 12) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "889E8C"))
                        
                        Text("за \(product.sessionCount) сессий")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Кнопка покупки
                    Button(action: action) {
                        HStack(spacing: 6) {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                                Text("Покупка...")
                                    .font(.subheadline)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.subheadline)
                                Text("Купить")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "889E8C"))
                        .cornerRadius(20)
                        .opacity(isPurchasing ? 0.7 : 1.0)
                    }
                    .disabled(isPurchasing)
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            product.isPopular ? Color.orange.opacity(0.3) : Color.clear,
                            lineWidth: 2
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}
