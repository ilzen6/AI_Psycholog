//
//  BiometricAuth.swift - ОКОНЧАТЕЛЬНОЕ ИСПРАВЛЕНИЕ Publishing changes
//  AI_Psycholog
//
//  КРИТИЧНО: УБРАНЫ все @Published обновления в canUseBiometrics
//

import LocalAuthentication
import SwiftUI

class BiometricAuth: ObservableObject {
    private let context = LAContext()
    
    // КРИТИЧНО: Убираем @Published чтобы избежать Publishing changes
    private var _biometricType: LABiometryType = .none
    private var _isAvailable = false
    
    // Computed свойства БЕЗ @Published
    var biometricType: LABiometryType {
        return _biometricType
    }
    
    var isAvailable: Bool {
        return _isAvailable
    }
    
    var canUseBiometrics: Bool {
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
        
        if canEvaluate {
            // КРИТИЧНО: НЕ обновляем @Published свойства!
            _biometricType = context.biometryType
            _isAvailable = true
            print("📱 BiometricAuth: Биометрия доступна - \(_biometricType == .faceID ? "Face ID" : "Touch ID")")
        } else {
            _isAvailable = false
            if let error = error {
                print("📱 BiometricAuth: Биометрия недоступна - \(error.localizedDescription)")
            }
        }
        
        return canEvaluate
    }
    
    // КРИТИЧНО: Простая версия authenticate БЕЗ @MainActor
    func authenticate(completion: @escaping (Bool, String?) -> Void) {
        print("📱 BiometricAuth: Начинаем биометрическую аутентификацию")
        
        let reason = "Войдите в приложение с помощью биометрии"
        
        // ВАЖНО: Используем новый context для каждой аутентификации
        let freshContext = LAContext()
        freshContext.localizedFallbackTitle = "Ввести пароль"
        freshContext.localizedCancelTitle = "Отмена"
        
        // Проверяем доступность еще раз
        var error: NSError?
        guard freshContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            let errorMsg = error?.localizedDescription ?? "Биометрия недоступна"
            print("📱 BiometricAuth: Биометрия недоступна - \(errorMsg)")
            DispatchQueue.main.async {
                completion(false, errorMsg)
            }
            return
        }
        
        // КРИТИЧНО: Выполняем аутентификацию НЕ в main thread
        freshContext.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, authError in
            DispatchQueue.main.async {
                if success {
                    print("📱 BiometricAuth: Аутентификация успешна")
                    completion(true, nil)
                } else {
                    let errorMessage = self.handleBiometricError(authError)
                    print("📱 BiometricAuth: Ошибка аутентификации - \(errorMessage)")
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    // Улучшенная обработка ошибок биометрии
    private func handleBiometricError(_ error: Error?) -> String {
        guard let authError = error else {
            return "Неизвестная ошибка аутентификации"
        }
        
        guard let laError = authError as? LAError else {
            return authError.localizedDescription
        }
        
        switch laError.code {
        case .userCancel:
            return "Аутентификация отменена пользователем"
        case .userFallback:
            return "Пользователь выбрал ввод пароля"
        case .systemCancel:
            return "Аутентификация отменена системой"
        case .passcodeNotSet:
            return "Не установлен код-пароль на устройстве"
        case .biometryNotAvailable:
            return "Биометрия недоступна на этом устройстве"
        case .biometryNotEnrolled:
            return "Биометрия не настроена"
        case .biometryLockout:
            return "Биометрия заблокирована. Введите код-пароль."
        case .authenticationFailed:
            return "Биометрическая аутентификация не удалась"
        case .invalidContext:
            return "Контекст аутентификации недействителен"
        case .notInteractive:
            return "Требуется взаимодействие пользователя"
        default:
            return "Неизвестная ошибка биометрии"
        }
    }
    
    func enableBiometrics(for username: String) {
        UserDefaults.standard.set(true, forKey: "biometrics_\(username)")
        print("📱 BiometricAuth: Биометрия включена для пользователя: \(username)")
    }
    
    func isBiometricsEnabled(for username: String) -> Bool {
        return UserDefaults.standard.bool(forKey: "biometrics_\(username)")
    }
    
    func disableBiometrics(for username: String) {
        UserDefaults.standard.removeObject(forKey: "biometrics_\(username)")
        print("📱 BiometricAuth: Биометрия отключена для пользователя: \(username)")
    }
    
    // НОВАЯ функция для инициализации БЕЗ Publishing changes
    func initializeBiometrics() {
        Task {
            let _ = canUseBiometrics // Просто вызываем для инициализации
        }
    }
}
