//
//  APIManager.swift - ПОЛНОСТЬЮ ИСПРАВЛЕННАЯ версия с правильным парсингом
//  AI_Psycholog
//
//  ИСПРАВЛЕНА ПРОБЛЕМА: Теперь правильно парсит формат {"content":[[5,"2025-07-04",3],[13,"2025-07-06",1]]}
//

import Foundation
import UIKit
import SwiftUI

class APIManager {
    static let shared = APIManager()
    
    // ПРОДАКШН URL - реальный сервер
    private let baseURL = "https://w-psycholog.com/API"
    
    // Настройки для продакшна
    private let timeout: TimeInterval = 30.0
    private let maxRetries = 3
    
    private init() {
        setupProductionEnvironment()
    }
    
    private func setupProductionEnvironment() {
        URLSession.shared.configuration.timeoutIntervalForRequest = timeout
        URLSession.shared.configuration.timeoutIntervalForResource = timeout * 2
        
        print("🌐 APIManager настроен для продакшн среды: \(baseURL)")
    }
    
    enum APIError: Error, LocalizedError {
        case invalidURL
        case noData
        case decodingError
        case serverError(String)
        case networkError(String)
        case unauthorized
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Неверный URL сервера"
            case .noData:
                return "Сервер не вернул данные"
            case .decodingError:
                return "Ошибка обработки данных сервера"
            case .serverError(let message):
                return message
            case .networkError(let message):
                return "Ошибка сети: \(message)"
            case .unauthorized:
                return "Необходима повторная авторизация"
            }
        }
    }
    
    // MARK: - Авторизация (ПРОДАКШН)
    func login(username: String, password: String, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/Account/Authorization") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AI-Psycholog iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = timeout
        
        let body = [
            "login": username.trimmingCharacters(in: .whitespacesAndNewlines),
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        performRequest(request: request) { result in
            switch result {
            case .success(let (data, response)):
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        let cookies = HTTPCookie.cookies(
                            withResponseHeaderFields: httpResponse.allHeaderFields as! [String: String],
                            for: url
                        )
                        let token = cookies.first(where: { $0.name == "authToken" })?.value ?? ""
                        let id = cookies.first(where: { $0.name == "id" })?.value ?? ""
                        
                        HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
                        
                        let loginResponse = LoginResponse(token: token, id: id)
                        completion(.success(loginResponse))
                        
                        print("✅ Успешная авторизация пользователя: \(username)")
                        
                    case 401:
                        completion(.failure(APIError.serverError("Неверный логин или пароль")))
                    case 429:
                        completion(.failure(APIError.serverError("Слишком много попыток входа. Попробуйте позже.")))
                    case 500...599:
                        completion(.failure(APIError.serverError("Сервер временно недоступен")))
                    default:
                        completion(.failure(APIError.serverError("Ошибка авторизации (\(httpResponse.statusCode))")))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - ИСПРАВЛЕННЫЙ метод загрузки сессий
    func getSessions(completion: @escaping (Result<[SessionData], Error>) -> Void) {
        print("🔍 APIManager: ИСПРАВЛЕННАЯ загрузка истории сессий с сервера...")
        
        guard let url = URL(string: "\(baseURL)/Session/History") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("AI-Psycholog iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = timeout
        
        // Добавляем куки авторизации
        if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
            let cookieHeader = HTTPCookie.requestHeaderFields(with: cookies)
            for (key, value) in cookieHeader {
                request.setValue(value, forHTTPHeaderField: key)
            }
            print("🍪 APIManager: Добавлены куки авторизации: \(cookies.count) шт.")
        } else {
            print("⚠️ APIManager: Нет сохраненных куки для авторизации")
        }
        
        performRequest(request: request) { result in
            switch result {
            case .success(let (data, response)):
                print("🔍 APIManager: Получен ответ от сервера")
                
                // Выводим сырой ответ для отладки
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📡 RAW Response: \(responseString)")
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 HTTP Status: \(httpResponse.statusCode)")
                    
                    switch httpResponse.statusCode {
                    case 200:
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            print("📊 Parsed JSON keys: \(json?.keys.joined(separator: ", ") ?? "none")")
                            
                            // ИСПРАВЛЕННЫЙ парсинг для формата {"content":[[5,"2025-07-04",3],[13,"2025-07-06",1]]}
                            var sessions: [SessionData] = []
                            
                            if let content = json?["content"] as? [[Any]] {
                                print("🔍 Формат: content как массив массивов (\(content.count) элементов)")
                                sessions = self.parseCorrectSessionFormat(content)
                            } else {
                                print("🔍 Неизвестный формат ответа")
                                sessions = []
                            }
                            
                            print("✅ APIManager: Обработано \(sessions.count) сессий")
                            sessions.forEach { session in
                                print("📊 Сессия #\(session.id): \(session.date) - \(session.moodLevel.title)")
                            }
                            
                            completion(.success(sessions.sorted { $0.date > $1.date }))
                            
                        } catch {
                            print("❌ APIManager: Ошибка парсинга JSON: \(error)")
                            completion(.failure(APIError.decodingError))
                        }
                        
                    case 401:
                        print("🔐 APIManager: Требуется повторная авторизация")
                        completion(.failure(APIError.unauthorized))
                        
                    case 404:
                        print("ℹ️ APIManager: История сессий не найдена (404)")
                        completion(.success([])) // Пустой массив если нет данных
                        
                    case 403:
                        print("🚫 APIManager: Доступ запрещен (403)")
                        completion(.failure(APIError.serverError("Доступ к истории сессий запрещен")))
                        
                    default:
                        print("❌ APIManager: Неожиданный HTTP статус: \(httpResponse.statusCode)")
                        completion(.failure(APIError.serverError("Ошибка загрузки истории сессий (\(httpResponse.statusCode))")))
                    }
                }
            case .failure(let error):
                print("❌ APIManager: Сетевая ошибка при загрузке сессий: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - ПРАВИЛЬНЫЙ парсер для формата [[5,"2025-07-04",3],[13,"2025-07-06",1]]
    private func parseCorrectSessionFormat(_ content: [[Any]]) -> [SessionData] {
        print("🔍 Парсим правильный формат сессий...")
        
        return content.compactMap { item -> SessionData? in
            guard item.count >= 3 else {
                print("⚠️ Элемент массива содержит недостаточно данных: \(item.count)")
                return nil
            }
            
            // ПРАВИЛЬНАЯ структура: [id, date, status]
            let id = item[0] as? Int ?? 0
            let dateString = item[1] as? String ?? ""
            let status = item[2] as? Int ?? 1
            
            print("🔍 Парсим сессию: id=\(id), date='\(dateString)', status=\(status)")
            
            // ИСПРАВЛЕНО: Парсим дату в формате "2025-07-04"
            guard let date = parseSimpleDateFormat(dateString) else {
                print("⚠️ Не удалось распарсить дату: '\(dateString)'")
                return nil
            }
            
            // ИСПРАВЛЕНО: Конвертируем status в настроение
            let moodLevel = convertStatusToMood(status)
            
            let sessionNote = "Сессия с AI-психологом от \(dateString)"
            
            print("✅ Успешно распарсена сессия #\(id): \(date) - \(moodLevel.title)")
            
            return SessionData(
                id: id,
                date: date,
                moodLevel: moodLevel,
                note: sessionNote
            )
        }
    }
    
    // ИСПРАВЛЕННЫЙ парсер дат для формата "2025-07-04"
    private func parseSimpleDateFormat(_ dateString: String) -> Date? {
        let cleanDateString = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanDateString.isEmpty else {
            print("❌ Пустая строка даты")
            return nil
        }
        
        print("🔍 Пытаемся распарсить дату: '\(cleanDateString)'")
        
        // Специально для формата "2025-07-04"
        let formatters = [
            "yyyy-MM-dd",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss",
            "dd.MM.yyyy",
            "MM/dd/yyyy"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.timeZone = TimeZone(identifier: "Europe/Moscow")
            formatter.locale = Locale(identifier: "en_US_POSIX") // ВАЖНО для "yyyy-MM-dd"
            
            if let date = formatter.date(from: cleanDateString) {
                print("✅ Дата успешно распарсена с форматом '\(format)': \(cleanDateString) -> \(date)")
                return date
            }
        }
        
        print("❌ Не удалось распарсить дату с любым форматом: '\(cleanDateString)'")
        return nil
    }
    
    // Конвертируем статус в настроение (на основе сайта: плохое=1, хорошее=3)
    private func convertStatusToMood(_ status: Int) -> MoodLevel {
        switch status {
        case 1:
            return .happy // ИСПРАВЛЕНО: 1 = хорошее настроение (солнышко на сайте)
        case 3:
            return .sad   // ИСПРАВЛЕНО: 3 = плохое настроение (дождик на сайте)
        default:
            return .neutral // По умолчанию нейтральное
        }
    }
    
    // MARK: - Регистрация (ПРОДАКШН)
    func register(data: [String: String], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/Account/Registration") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AI-Psycholog iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = timeout
        
        var cleanData = data
        cleanData["login"] = data["login"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanData["email"] = data["email"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanData["phone"] = data["phone"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: cleanData)
        } catch {
            completion(.failure(error))
            return
        }
        
        performRequest(request: request) { result in
            switch result {
            case .success(let (_, response)):
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 201:
                        completion(.success(()))
                        print("✅ Успешная регистрация: \(cleanData["login"] ?? "unknown")")
                    case 409:
                        completion(.failure(APIError.serverError("Пользователь с таким логином уже существует")))
                    case 422:
                        completion(.failure(APIError.serverError("Данные не соответствуют требованиям сервера")))
                    case 400:
                        completion(.failure(APIError.serverError("Проверьте правильность введенных данных")))
                    default:
                        completion(.failure(APIError.serverError("Ошибка регистрации (\(httpResponse.statusCode))")))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Профиль (ПРОДАКШН)
    func getProfile(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/Account/About") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("AI-Psycholog iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = timeout
        
        performRequest(request: request) { result in
            switch result {
            case .success(let (data, response)):
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let content = json?["content"] as? [[Any]],
                               let firstUser = content.first {
                                
                                let profile = UserProfile(
                                    fullName: firstUser[1] as? String ?? "",
                                    email: firstUser[3] as? String ?? "",
                                    phone: firstUser[2] as? String ?? "",
                                    sessionBalance: firstUser[4] as? Int ?? 0,
                                    avatarURL: firstUser[5] as? String
                                )
                                completion(.success(profile))
                                print("✅ Загружен профиль: \(profile.fullName)")
                            } else {
                                completion(.failure(APIError.decodingError))
                            }
                        } catch {
                            completion(.failure(APIError.decodingError))
                        }
                    case 401:
                        completion(.failure(APIError.unauthorized))
                    default:
                        completion(.failure(APIError.serverError("Ошибка загрузки профиля")))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Создание сессии (ПРОДАКШН)
    func createSession(completion: @escaping (Result<SessionInfo, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/Session") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("AI-Psycholog iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = timeout
        
        performRequest(request: request) { result in
            switch result {
            case .success(let (data, response)):
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200, 201:
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            let sessionInfo = SessionInfo(
                                id: json?["id"] as? Int,
                                isNew: (json?["isNew"] as? Int) == 1
                            )
                            completion(.success(sessionInfo))
                            print("✅ Сессия создана/получена: ID=\(sessionInfo.id ?? 0), новая=\(sessionInfo.isNew)")
                        } catch {
                            completion(.failure(APIError.decodingError))
                        }
                    case 401:
                        completion(.failure(APIError.unauthorized))
                    default:
                        completion(.failure(APIError.serverError("Ошибка создания сессии")))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Добавление записи настроения (ПРОДАКШН)
    func addMoodRecord(moodLevel: MoodLevel, note: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/Mood/Add") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AI-Psycholog iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = timeout
        
        let body: [String: Any] = [
            "mood": moodLevel.rawValue,
            "score": moodLevel.score,
            "note": note.trimmingCharacters(in: .whitespacesAndNewlines),
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        performRequest(request: request) { result in
            switch result {
            case .success(let (_, response)):
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200, 201:
                        completion(.success(()))
                        print("✅ Запись настроения сохранена: \(moodLevel.title)")
                    case 401:
                        completion(.failure(APIError.unauthorized))
                    case 400:
                        completion(.failure(APIError.serverError("Неверные данные настроения")))
                    default:
                        completion(.failure(APIError.serverError("Ошибка сохранения настроения")))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Оплата через веб (ПРОДАКШН)
    func confirmPayment(packageId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/Session") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AI-Psycholog iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = timeout
        
        let body = ["index": packageId]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("💳 Создаем платеж для пакета #\(packageId)")
        } catch {
            completion(.failure(error))
            return
        }
        
        performRequest(request: request) { result in
            switch result {
            case .success(let (data, response)):
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 202:
                        // Получаем URL для оплаты
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let paymentURL = json["url"] as? String {
                            print("🔗 Получен URL для оплаты: \(paymentURL)")
                            // Открываем URL оплаты в Safari
                            if let url = URL(string: paymentURL) {
                                DispatchQueue.main.async {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                        completion(.success(()))
                        
                    case 200:
                        print("✅ Платеж успешен")
                        completion(.success(()))
                        
                    case 401:
                        completion(.failure(APIError.unauthorized))
                        
                    case 400:
                        completion(.failure(APIError.serverError("Неверные параметры пакета")))
                        
                    case 403:
                        completion(.failure(APIError.serverError("Недостаточно прав")))
                        
                    case 404:
                        completion(.failure(APIError.serverError("Пакет не найден")))
                        
                    default:
                        completion(.failure(APIError.serverError("Ошибка платежа (\(httpResponse.statusCode))")))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Получение статистики настроения (ПРОДАКШН)
    func getMoodStatistics(completion: @escaping (Result<MoodStatistics, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/Mood/Statistics") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("AI-Psycholog iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = timeout
        
        performRequest(request: request) { result in
            switch result {
            case .success(let (data, response)):
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            
                            let statistics = MoodStatistics(
                                totalSessions: json?["totalSessions"] as? Int ?? 0,
                                averageScore: json?["averageScore"] as? Double ?? 0.0,
                                streakDays: json?["streakDays"] as? Int ?? 0,
                                sessionsThisMonth: json?["sessionsThisMonth"] as? Int ?? 0
                            )
                            
                            completion(.success(statistics))
                            print("✅ Загружена статистика настроений")
                        } catch {
                            completion(.failure(APIError.decodingError))
                        }
                        
                    case 401:
                        completion(.failure(APIError.unauthorized))
                        
                    case 404:
                        // Нет статистики - создаем пустую
                        let emptyStats = MoodStatistics(totalSessions: 0, averageScore: 0.0, streakDays: 0, sessionsThisMonth: 0)
                        completion(.success(emptyStats))
                        
                    default:
                        completion(.failure(APIError.serverError("Ошибка загрузки статистики")))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Вспомогательные методы
    
    private func performRequest(request: URLRequest, completion: @escaping (Result<(Data, URLResponse), Error>) -> Void) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    if error.localizedDescription.contains("timed out") {
                        completion(.failure(APIError.networkError("Превышено время ожидания ответа сервера")))
                    } else if error.localizedDescription.contains("Internet connection") {
                        completion(.failure(APIError.networkError("Отсутствует подключение к интернету")))
                    } else {
                        completion(.failure(APIError.networkError(error.localizedDescription)))
                    }
                    return
                }
                
                guard let data = data, let response = response else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                completion(.success((data, response)))
            }
        }.resume()
    }
}

// MARK: - Response Models

struct LoginResponse {
    let token: String
    let id: String
}

struct SessionInfo {
    let id: Int?
    let isNew: Bool
}

struct MoodStatistics {
    let totalSessions: Int
    let averageScore: Double
    let streakDays: Int
    let sessionsThisMonth: Int
}
