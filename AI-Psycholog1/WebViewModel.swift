//
//  WebViewModel.swift - УЛУЧШЕННЫЙ с полной поддержкой звонков
//  AI_Psycholog
//
//  ДОБАВЛЕНО: Полная обработка всех типов звонков и WebRTC
//

import Foundation
import WebKit
import Combine
import UIKit

class WebViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    
    private var webView: WKWebView?
    var messageHandlers: [String: ([String: Any]) -> Void] = [:]
    
    func setWebView(_ webView: WKWebView) {
        self.webView = webView
    }
    
    func evaluateJavaScript(_ script: String) {
        webView?.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("JavaScript error: \(error)")
            }
        }
    }
        
    // НОВЫЕ методы для обработки звонков
    private func handleCallMessage(data: [String: Any]) {
        print("📞 WebViewModel: Обработка звонка")
        print("📞 Данные звонка: \(data)")
        
        // Извлекаем информацию о звонке
        var phoneNumber: String?
        var callURL: String?
        
        if let phone = data["phone"] as? String, !phone.isEmpty {
            phoneNumber = phone
        }
        
        if let url = data["url"] as? String, !url.isEmpty {
            callURL = url
        }
        
        // Проверяем data атрибуты
        if let callData = data["data"] as? [String: Any] {
            if let dataPhone = callData["data-phone"] as? String {
                phoneNumber = dataPhone
            }
            if let dataCall = callData["data-call"] as? String {
                callURL = dataCall
            }
        }
        
        // Пытаемся извлечь номер из HTML
        if let buttonHTML = data["buttonHTML"] as? String {
            phoneNumber = extractPhoneFromHTML(buttonHTML) ?? phoneNumber
        }
        
        if let buttonText = data["buttonText"] as? String {
            phoneNumber = extractPhoneFromText(buttonText) ?? phoneNumber
        }
        
        print("📞 Extracted phone: \(phoneNumber ?? "none")")
        print("📞 Extracted URL: \(callURL ?? "none")")
        
        // Выполняем звонок
        if let phone = phoneNumber {
            makePhoneCall(phoneNumber: phone)
        } else if let url = callURL {
            openExternalURL(urlString: url)
        } else {
            print("❌ WebViewModel: Не удалось извлечь данные для звонка")
            showCallError()
        }
    }
    
    private func handleSignedURL(data: [String: Any]) {
        print("🔗 WebViewModel: Обработка signed URL")
        
        guard let urlString = data["url"] as? String else {
            print("❌ WebViewModel: Нет URL в signed URL данных")
            return
        }
        
        print("🔗 Signed URL: \(urlString)")
        
        // Проверяем, это звонок или обычная ссылка
        if urlString.contains("call") || urlString.contains("webrtc") ||
           urlString.contains("meet") || urlString.contains("video") {
            print("📞 Detected call URL in signed URL")
            openCallURL(urlString)
        } else {
            openExternalURL(urlString: urlString)
        }
    }
    
    private func handleWindowOpenCall(data: [String: Any]) {
        print("🪟 WebViewModel: Обработка window.open звонка")
        
        if let urlString = data["url"] as? String {
            print("🪟 Window.open URL: \(urlString)")
            openCallURL(urlString)
        }
    }
    
    private func handleWebRTCRequest(data: [String: Any]) {
        print("📹 WebViewModel: WebRTC запрос")
        print("📹 Constraints: \(data)")
        
        // Можно добавить дополнительную логику для WebRTC
        // Например, показать индикатор активного звонка
    }
    
    private func handleExternalURL(data: [String: Any]) {
        guard let urlString = data["url"] as? String else { return }
        openExternalURL(urlString: urlString)
    }
    
    // ВСПОМОГАТЕЛЬНЫЕ методы
    private func extractPhoneFromHTML(_ html: String) -> String? {
        // Ищем номер телефона в HTML атрибутах
        let patterns = [
            "data-phone=\"([^\"]+)\"",
            "data-call=\"([^\"]+)\"",
            "href=\"tel:([^\"]+)\"",
            "onclick=\"[^\"]*call[^\"]*([+]?[0-9\\s\\-\\(\\)]{7,})"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..., in: html)
                if let match = regex.firstMatch(in: html, range: range) {
                    if match.numberOfRanges > 1 {
                        let phoneRange = match.range(at: 1)
                        if let swiftRange = Range(phoneRange, in: html) {
                            let phone = String(html[swiftRange])
                            print("📞 Extracted phone from HTML: \(phone)")
                            return phone
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractPhoneFromText(_ text: String) -> String? {
        // Ищем номер телефона в тексте
        let phonePattern = "[+]?[0-9\\s\\-\\(\\)]{7,}"
        
        if let regex = try? NSRegularExpression(pattern: phonePattern) {
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: range) {
                if let swiftRange = Range(match.range, in: text) {
                    let phone = String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    print("📞 Extracted phone from text: \(phone)")
                    return phone
                }
            }
        }
        
        return nil
    }
    
    private func makePhoneCall(phoneNumber: String) {
        let cleanNumber = phoneNumber.replacingOccurrences(of: "[^+0-9]", with: "", options: .regularExpression)
        
        guard !cleanNumber.isEmpty else {
            print("❌ WebViewModel: Некорректный номер телефона: \(phoneNumber)")
            showCallError()
            return
        }
        
        let telURL = "tel:\(cleanNumber)"
        print("📞 WebViewModel: Выполняем звонок на \(cleanNumber)")
        
        openExternalURL(urlString: telURL)
    }
    // Добавьте только эти методы в существующий WebViewModel.swift

    func handleMessage(type: String, data: [String: Any]) {
        print("📱 WebViewModel: Обработка сообщения типа \(type)")
        
        // Обработка WebRTC сообщений
        switch type {
        case "webrtcMediaRequest":
            print("🎤 WebRTC запрос медиа: \(data)")
        case "webrtcStreamObtained":
            print("✅ WebRTC поток получен: \(data)")
        case "webrtcError":
            print("❌ WebRTC ошибка: \(data)")
        case "audioButtonClicked":
            print("🎤 Кнопка аудио нажата: \(data)")
        default:
            // Обычные обработчики
            if let handler = messageHandlers[type] {
                handler(data)
            } else {
                print("⚠️ WebViewModel: Нет обработчика для типа \(type)")
            }
        }
    }
    
    private func openCallURL(_ urlString: String) {
        print("📞 WebViewModel: Открываем URL звонка: \(urlString)")
        
        // Для signed URL или WebRTC ссылок пытаемся открыть в Safari
        guard let url = URL(string: urlString) else {
            print("❌ WebViewModel: Некорректный URL: \(urlString)")
            return
        }
        
        DispatchQueue.main.async {
            // Если это обычная веб-ссылка для звонка, открываем в Safari
            if urlString.hasPrefix("http") {
                UIApplication.shared.open(url) { success in
                    print("📞 WebViewModel: Safari open result: \(success)")
                    if !success {
                        self.showCallError()
                    }
                }
            } else {
                // Для других схем пытаемся открыть как обычно
                self.openExternalURL(urlString: urlString)
            }
        }
    }
    
    private func openExternalURL(urlString: String) {
        guard let url = URL(string: urlString) else {
            print("❌ WebViewModel: Некорректный URL: \(urlString)")
            return
        }
        
        print("🔗 WebViewModel: Попытка открыть URL: \(urlString)")
        
        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    if success {
                        print("✅ WebViewModel: Успешно открыт \(urlString)")
                    } else {
                        print("❌ WebViewModel: Не удалось открыть \(urlString)")
                        
                        if urlString.hasPrefix("tel:") {
                            self.showPhoneAlert(phoneNumber: urlString.replacingOccurrences(of: "tel:", with: ""))
                        } else {
                            self.showCallError()
                        }
                    }
                }
            } else {
                print("❌ WebViewModel: Устройство не может открыть URL: \(urlString)")
                
                if urlString.hasPrefix("tel:") {
                    self.showPhoneAlert(phoneNumber: urlString.replacingOccurrences(of: "tel:", with: ""))
                } else {
                    self.showCallError()
                }
            }
        }
    }
    
    private func showPhoneAlert(phoneNumber: String) {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                return
            }
            
            let alert = UIAlertController(
                title: "Позвонить",
                message: "Хотите позвонить по номеру \(phoneNumber)?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Позвонить", style: .default) { _ in
                if let url = URL(string: "tel:\(phoneNumber)") {
                    UIApplication.shared.open(url)
                }
            })
            
            alert.addAction(UIAlertAction(title: "Скопировать номер", style: .default) { _ in
                UIPasteboard.general.string = phoneNumber
            })
            
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            
            // Находим самый верхний view controller
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            topController.present(alert, animated: true)
        }
    }
    
    private func showCallError() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                return
            }
            
            let alert = UIAlertController(
                title: "Ошибка звонка",
                message: "Не удалось выполнить звонок. Проверьте настройки устройства.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            topController.present(alert, animated: true)
        }
    }
    
    // МЕТОДЫ ДЛЯ ОТЛАДКИ
    func debugWebViewContent() {
        let debugScript = """
        console.log('🔍 DEBUG: Searching for call elements...');
        
        // Ищем все возможные элементы для звонков
        var callElements = [];
        
        // 1. Ссылки tel:
        var telLinks = document.querySelectorAll('a[href^="tel:"]');
        telLinks.forEach(function(link) {
            callElements.push({type: 'tel-link', href: link.href, text: link.textContent});
        });
        
        // 2. Кнопки с data-phone
        var phoneButtons = document.querySelectorAll('[data-phone]');
        phoneButtons.forEach(function(btn) {
            callElements.push({type: 'data-phone', phone: btn.dataset.phone, text: btn.textContent});
        });
        
        // 3. Кнопки с data-call
        var callButtons = document.querySelectorAll('[data-call]');
        callButtons.forEach(function(btn) {
            callElements.push({type: 'data-call', call: btn.dataset.call, text: btn.textContent});
        });
        
        // 4. Кнопки с классами call/phone
        var classButtons = document.querySelectorAll('.call-button, .phone-button, .call, .phone');
        classButtons.forEach(function(btn) {
            callElements.push({type: 'class-button', className: btn.className, text: btn.textContent});
        });
        
        // 5. Кнопки с текстом о звонках
        var allButtons = document.querySelectorAll('button, [role="button"]');
        allButtons.forEach(function(btn) {
            var text = btn.textContent || btn.innerText || '';
            if (text.toLowerCase().includes('звонок') || text.toLowerCase().includes('позвонить') || 
                text.toLowerCase().includes('call') || text.toLowerCase().includes('phone')) {
                callElements.push({type: 'text-button', text: text, onclick: btn.onclick ? btn.onclick.toString() : null});
            }
        });
        
        console.log('🔍 Found call elements:', callElements);
        
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.iOS) {
            window.webkit.messageHandlers.iOS.postMessage({
                type: 'debugCallElements',
                elements: callElements
            });
        }
        
        return callElements;
        """
        
        evaluateJavaScript(debugScript)
    }
}
