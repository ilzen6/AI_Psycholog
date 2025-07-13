//
//  MockPaymentManager.swift - исправленная версия с 3 продуктами
//  AI_Psycholog
//
//  Убран 4-й продукт (15 сессий), оставлены только 3 варианта
//

import Foundation
import SwiftUI

// MARK: - Mock Product (имитация StoreKit Product)
struct MockProduct: Identifiable {
    let id: String
    let displayName: String
    let description: String
    let price: Double // Изменено с Decimal на Double
    let displayPrice: String
    let sessionCount: Int
    let isPopular: Bool
    
    static let allProducts: [MockProduct] = [
        MockProduct(
            id: "sessions_5pack",
            displayName: "Стартовый пакет",
            description: "Познакомьтесь с AI-психологом",
            price: 2000.0,  // ИСПРАВЛЕНО: было 199.0
            displayPrice: "2000 ₽", // ИСПРАВЛЕНО: было "199 ₽"
            sessionCount: 5,
            isPopular: false
        ),
        MockProduct(
            id: "sessions_7pack",
            displayName: "Популярный выбор",
            description: "Оптимальное соотношение цены и качества",
            price: 2500.0,  // ИСПРАВЛЕНО: было 299.0
            displayPrice: "2500 ₽", // ИСПРАВЛЕНО: было "299 ₽"
            sessionCount: 7,
            isPopular: true
        ),
        MockProduct(
            id: "sessions_10pack",
            displayName: "Максимальная выгода",
            description: "Больше сессий - больше экономия",
            price: 3000.0,  // ИСПРАВЛЕНО: было 399.0
            displayPrice: "3000 ₽", // ИСПРАВЛЕНО: было "399 ₽"
            sessionCount: 10,
            isPopular: false
        )
    ]
}

// MARK: - Mock Payment Manager
@MainActor
class MockPaymentManager: ObservableObject {
    static let shared = MockPaymentManager()
    
    @Published var products: [MockProduct] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var purchasedProducts: Set<String> = []
    
    private init() {}
    
    // MARK: - Загрузка продуктов (имитация)
    func loadProducts() async {
        print("🛒 Загружаем mock продукты...")
        isLoading = true
        errorMessage = ""
        
        // Имитируем задержку сети
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 секунды
        
        // Имитируем возможную ошибку сети (5% шанс)
        if Bool.random() && Int.random(in: 1...20) == 1 {
            errorMessage = "Ошибка сети (имитация)"
            isLoading = false
            print("❌ Mock ошибка загрузки продуктов")
            return
        }
        
        products = MockProduct.allProducts
        isLoading = false
        
        print("✅ Mock продукты загружены: \(products.count) шт.")
        products.forEach { product in
            print("   - \(product.displayName): \(product.sessionCount) сессий за \(product.displayPrice)")
        }
    }
    
    // MARK: - Покупка (имитация)
    func purchase(_ product: MockProduct) async -> Bool {
        print("🛒 Начинаем mock покупку: \(product.displayName)")
        isLoading = true
        errorMessage = ""
        
        // Имитируем процесс покупки (2-4 секунды)
        let delay = Double.random(in: 2.0...4.0)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        // Имитируем успешную покупку (95% успеха)
        let success = Int.random(in: 1...20) != 1 // 19/20 шанс успеха
        
        if success {
            purchasedProducts.insert(product.id)
            addSessionsToUser(product.sessionCount)
            
            // Сохраняем историю покупок для демонстрации
            savePurchaseHistory(product)
            
            print("✅ Mock покупка успешна: \(product.displayName) (+\(product.sessionCount) сессий)")
        } else {
            errorMessage = "Имитация ошибки платежа. Попробуйте еще раз."
            print("❌ Mock покупка неудачна: \(product.displayName)")
        }
        
        isLoading = false
        return success
    }
    
    // MARK: - Восстановление покупок (имитация)
    func restorePurchases() async {
        print("🔄 Восстанавливаем mock покупки...")
        isLoading = true
        
        // Имитируем восстановление
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 секунды
        
        // В демо-режиме можем восстановить несколько случайных покупок
        let restoredPurchases = MockProduct.allProducts.prefix(Int.random(in: 0...2))
        var totalRestored = 0
        
        for product in restoredPurchases {
            if !purchasedProducts.contains(product.id) {
                purchasedProducts.insert(product.id)
                totalRestored += product.sessionCount
            }
        }
        
        if totalRestored > 0 {
            addSessionsToUser(totalRestored)
            print("✅ Mock восстановлено: \(totalRestored) сессий")
        } else {
            print("ℹ️ Mock восстановление: новых покупок не найдено")
        }
        
        isLoading = false
    }
    
    // MARK: - Добавление сессий пользователю
    private func addSessionsToUser(_ count: Int) {
        let currentBalance = UserDefaults.standard.integer(forKey: "localSessionBalance")
        let newBalance = currentBalance + count
        UserDefaults.standard.set(newBalance, forKey: "localSessionBalance")
        
        print("💰 Добавлено \(count) сессий. Локальный баланс: \(currentBalance) → \(newBalance)")
        
        // Уведомляем другие части приложения об обновлении баланса
        NotificationCenter.default.post(name: NSNotification.Name("SessionBalanceUpdated"), object: nil)
        
        // В будущем здесь будет вызов API для синхронизации с сервером
        // APIManager.shared.syncSessionBalance(newBalance) { ... }
    }
    
    // MARK: - Получение текущего баланса
    func getCurrentSessionBalance() -> Int {
        let balance = UserDefaults.standard.integer(forKey: "localSessionBalance")
        print("📊 Текущий локальный баланс сессий: \(balance)")
        return balance
    }
    
    // MARK: - Сохранение истории покупок (для демо)
    private func savePurchaseHistory(_ product: MockProduct) {
        var history = UserDefaults.standard.array(forKey: "mockPurchaseHistory") as? [[String: Any]] ?? []
        
        let purchase = [
            "id": product.id,
            "name": product.displayName,
            "sessions": product.sessionCount,
            "price": product.displayPrice,
            "date": Date().timeIntervalSince1970
        ] as [String : Any]
        
        history.append(purchase)
        
        // Сохраняем только последние 20 покупок
        if history.count > 20 {
            history = Array(history.suffix(20))
        }
        
        UserDefaults.standard.set(history, forKey: "mockPurchaseHistory")
        print("📝 Сохранена история покупки: \(product.displayName)")
    }
    
    // MARK: - Получение истории покупок (для демо)
    func getPurchaseHistory() -> [[String: Any]] {
        return UserDefaults.standard.array(forKey: "mockPurchaseHistory") as? [[String: Any]] ?? []
    }
    
    // MARK: - Сброс данных (для тестирования)
    func resetAllData() {
        print("🔄 Сброс всех mock данных...")
        
        UserDefaults.standard.removeObject(forKey: "localSessionBalance")
        UserDefaults.standard.removeObject(forKey: "mockPurchaseHistory")
        purchasedProducts.removeAll()
        
        NotificationCenter.default.post(name: NSNotification.Name("SessionBalanceUpdated"), object: nil)
        
        print("✅ Mock данные сброшены")
    }
    
    // MARK: - Валидация продуктов
    func validateProducts() -> Bool {
        let validProducts = products.allSatisfy { product in
            product.sessionCount > 0 && product.price > 0
        }
        
        if !validProducts {
            errorMessage = "Некорректные данные продуктов"
            print("❌ Валидация продуктов не пройдена")
        }
        
        return validProducts
    }
}
