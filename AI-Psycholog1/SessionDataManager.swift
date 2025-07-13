//
//  SessionDataManager.swift - ПОЛНОСТЬЮ ИСПРАВЛЕННАЯ версия БЕЗ @MainActor
//  AI_Psycholog
//
//  КРИТИЧНО: УБРАН @MainActor - это источник Publishing changes ошибок!
//

import Foundation
import SwiftUI

// MARK: - Shared Session Model (без изменений)
struct SessionData: Identifiable, Codable {
    let id: Int
    let date: Date
    let moodLevel: MoodLevel
    let note: String
    
    enum CodingKeys: String, CodingKey {
        case id, date, moodLevel, note
    }
    
    init(id: Int, date: Date, moodLevel: MoodLevel, note: String = "") {
        self.id = id
        self.date = date
        self.moodLevel = moodLevel
        self.note = note
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        moodLevel = try container.decode(MoodLevel.self, forKey: .moodLevel)
        note = try container.decode(String.self, forKey: .note)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(moodLevel, forKey: .moodLevel)
        try container.encode(note, forKey: .note)
    }
}

// MARK: - ИСПРАВЛЕННЫЙ Session Data Manager БЕЗ @MainActor
class SessionDataManager: ObservableObject {
    static let shared = SessionDataManager()
    
    @Published var sessions: [SessionData] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private(set) var lastLoadTime: Date?
    private let cacheExpirationTime: TimeInterval = 300 // 5 минут кеш
    private var debugInfo: [String] = []
    
    private init() {
        print("📊 SessionDataManager инициализирован БЕЗ @MainActor")
        addDebugInfo("📊 SessionDataManager инициализирован")
    }
    
    // MARK: - ИСПРАВЛЕННАЯ загрузка сессий с сервера
    func loadSessionsFromServer() {
        print("📊 🔄 Загрузка истории сессий с сервера...")
        addDebugInfo("🔄 Начинаем загрузку истории сессий")
        
        // КРИТИЧНО: Обновляем состояние через DispatchQueue.main.async
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        // Используем APIManager
        APIManager.shared.getSessions { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let serverSessions):
                    let sessionCount = serverSessions.count
                    print("✅ SessionDataManager: УСПЕШНО получено \(sessionCount) сессий с сервера")
                    self.addDebugInfo("✅ Успешно получено \(sessionCount) сессий")
                    
                    if serverSessions.isEmpty {
                        print("ℹ️ На сервере пока нет сессий с AI-психологом")
                        self.addDebugInfo("ℹ️ Сервер вернул пустой список сессий")
                        self.checkAuthenticationStatus()
                    } else {
                        print("📊 ДЕТАЛИ загруженных сессий:")
                        self.addDebugInfo("📊 ДЕТАЛИ сессий:")
                        serverSessions.enumerated().forEach { index, session in
                            let logLine = "  \(index + 1). Сессия #\(session.id) - \(session.date) - \(session.moodLevel.title)"
                            print(logLine)
                            self.addDebugInfo(logLine)
                        }
                    }
                    
                    self.sessions = serverSessions.sorted { $0.date > $1.date }
                    self.lastLoadTime = Date()
                    self.error = nil
                    
                    // Уведомляем интерфейс
                    NotificationCenter.default.post(name: .sessionDataUpdated, object: nil)
                    
                    print("✅ Данные успешно обновлены, уведомление отправлено")
                    self.addDebugInfo("✅ Интерфейс уведомлен об обновлении данных")
                    
                case .failure(let apiError):
                    print("❌ SessionDataManager: ОШИБКА загрузки сессий")
                    print("❌ Детали ошибки: \(apiError)")
                    
                    self.addDebugInfo("❌ ОШИБКА загрузки сессий")
                    self.addDebugInfo("❌ \(apiError.localizedDescription)")
                    
                    // Детальный анализ ошибки
                    if apiError.localizedDescription.contains("Необходима повторная авторизация") ||
                       apiError.localizedDescription.contains("401") {
                        self.error = "Требуется повторный вход в аккаунт"
                        self.addDebugInfo("🔐 Проблема с авторизацией - требуется повторный логин")
                        self.checkAuthenticationStatus()
                    } else if apiError.localizedDescription.contains("Отсутствует подключение") ||
                              apiError.localizedDescription.contains("Internet connection") {
                        self.error = "Нет подключения к интернету"
                        self.addDebugInfo("📡 Проблема с интернет-соединением")
                    } else if apiError.localizedDescription.contains("время ожидания") ||
                              apiError.localizedDescription.contains("timed out") {
                        self.error = "Сервер не отвечает, попробуйте позже"
                        self.addDebugInfo("⏰ Таймаут сервера")
                    } else {
                        self.error = "Ошибка загрузки данных: \(apiError.localizedDescription)"
                        self.addDebugInfo("❓ Неопределенная ошибка API")
                    }
                    
                    print("ℹ️ Без корректного ответа сервера данные недоступны")
                    self.addDebugInfo("ℹ️ Данные недоступны без корректного ответа сервера")
                }
                
                // В любом случае уведомляем об обновлении
                NotificationCenter.default.post(name: .sessionDataUpdated, object: nil)
            }
        }
    }
    
    // MARK: - Проверка статуса авторизации
    private func checkAuthenticationStatus() {
        addDebugInfo("🔍 Проверяем статус авторизации...")
        
        // Проверяем наличие сохраненных куки
        if let url = URL(string: "https://w-psycholog.com") {
            let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
            addDebugInfo("🍪 Найдено куки: \(cookies.count)")
            
            for cookie in cookies {
                addDebugInfo("   - \(cookie.name): \(cookie.value.prefix(10))...")
            }
            
            if cookies.isEmpty {
                addDebugInfo("⚠️ Куки авторизации отсутствуют")
            }
        }
        
        // Проверяем сохраненные учетные данные
        if let credentials = KeychainManager.shared.getCredentials() {
            addDebugInfo("🔐 Найдены сохраненные учетные данные для: \(credentials.username)")
        } else {
            addDebugInfo("⚠️ Сохраненные учетные данные не найдены")
        }
    }
    
    // MARK: - Add New Session via API
    func addSession(moodLevel: MoodLevel, note: String = "") {
        print("📊 Добавляем запись сессии через API...")
        addDebugInfo("📊 Добавляем новую сессию: \(moodLevel.title)")
        
        // Отправляем на сервер
        APIManager.shared.addMoodRecord(moodLevel: moodLevel, note: note) { [weak self] (result: Result<Void, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Запись сессии сохранена на сервере")
                    self?.addDebugInfo("✅ Сессия сохранена на сервере")
                    // Перезагружаем данные с сервера для синхронизации
                    self?.refreshData()
                    
                case .failure(let error):
                    print("❌ Ошибка сохранения сессии: \(error)")
                    self?.addDebugInfo("❌ Ошибка сохранения: \(error.localizedDescription)")
                    self?.error = "Не удалось сохранить сессию. Проверьте подключение к интернету."
                }
            }
        }
    }
    
    // MARK: - Create Session from Chat
    func createSessionFromChat(moodLevel: MoodLevel? = nil, note: String = "", completion: @escaping (Bool) -> Void) {
        print("📊 Создаем сессию через чат...")
        addDebugInfo("📊 Создаем сессию через чат")
        
        // Создаем сессию через API
        APIManager.shared.createSession { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let sessionInfo):
                    if sessionInfo.isNew {
                        // Если указано настроение, сохраняем его
                        if let mood = moodLevel {
                            self?.addSession(moodLevel: mood, note: note)
                        }
                        print("✅ Создана новая сессия #\(sessionInfo.id ?? 0)")
                        self?.addDebugInfo("✅ Создана новая сессия #\(sessionInfo.id ?? 0)")
                    } else {
                        print("ℹ️ Сессия уже существует")
                        self?.addDebugInfo("ℹ️ Сессия уже существует")
                        // Все равно обновляем данные
                        self?.refreshData()
                    }
                    completion(true)
                    
                case .failure(let error):
                    print("❌ Ошибка создания сессии: \(error)")
                    self?.addDebugInfo("❌ Ошибка создания сессии: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Get Sessions for Profile View
    func getSessionsForProfile() -> [ProfileSession] {
        print("📊 Запрос сессий для профиля: \(sessions.count) реальных сессий")
        addDebugInfo("📊 Предоставляем \(sessions.count) сессий для профиля")
        
        return sessions.map { session in
            // Конвертируем MoodLevel в SessionStatus
            let status: ProfileSession.SessionStatus
            switch session.moodLevel.score {
            case 1, 2:
                status = .bad
            case 4, 5:
                status = .good
            default:
                status = .good // По умолчанию хорошее
            }
            
            return ProfileSession(
                id: session.id,
                date: session.date,
                status: status
            )
        }.sorted { $0.date > $1.date }
    }
    
    // MARK: - Statistics
    func getAverageMoodScore() -> Double {
        guard !sessions.isEmpty else {
            print("📊 Средний балл: 0 (нет сессий)")
            return 0
        }
        let sum = sessions.reduce(0) { $0 + $1.moodLevel.score }
        let average = Double(sum) / Double(sessions.count)
        print("📊 Средний балл настроения по \(sessions.count) сессиям: \(String(format: "%.1f", average))")
        return average
    }
    
    func getStreakDays() -> Int {
        guard !sessions.isEmpty else {
            print("📊 Дней подряд: 0 (нет сессий)")
            return 0
        }
        
        let calendar = Calendar.current
        let sortedSessions = sessions.sorted { $0.date > $1.date }
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // Группируем сессии по дням
        let sessionsByDay = Dictionary(grouping: sortedSessions) { session in
            calendar.startOfDay(for: session.date)
        }
        
        // Проверяем последовательность дней
        while let _ = sessionsByDay[currentDate] {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        print("📊 Подряд дней с сессиями: \(streak)")
        return streak
    }
    
    func getSessionsCount(for period: TimeFilter) -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        let count = sessions.filter { session in
            switch period {
            case .week:
                return calendar.isDate(session.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(session.date, equalTo: now, toGranularity: .month)
            case .year:
                return calendar.isDate(session.date, equalTo: now, toGranularity: .year)
            case .all:
                return true
            }
        }.count
        
        print("📊 Сессий за период \(period.title): \(count)")
        return count
    }
    
    func getSessionsThisMonth() -> Int {
        return getSessionsCount(for: .month)
    }
    
    // MARK: - Refresh Data
    func refreshData() {
        print("🔄 ПРИНУДИТЕЛЬНОЕ обновление данных сессий с сервера")
        addDebugInfo("🔄 Принудительное обновление данных")
        
        DispatchQueue.main.async {
            self.lastLoadTime = nil // Сбрасываем кеш
            self.sessions.removeAll() // Очищаем текущие данные
            self.error = nil // Сбрасываем ошибки
        }
        
        loadSessionsFromServer()
    }
    
    // MARK: - Clear Data
    func clearLocalData() {
        DispatchQueue.main.async {
            self.sessions.removeAll()
            self.lastLoadTime = nil
            self.error = nil
            self.debugInfo.removeAll()
        }
        NotificationCenter.default.post(name: .sessionDataUpdated, object: nil)
        print("🗑️ Локальные данные сессий очищены")
    }
    
    // MARK: - Cache Management
    private func isCacheValid() -> Bool {
        guard let lastLoad = lastLoadTime else { return false }
        let isValid = Date().timeIntervalSince(lastLoad) < cacheExpirationTime
        print("📊 Кеш валиден: \(isValid) (последняя загрузка: \(lastLoad))")
        return isValid
    }
    
    func forceCacheRefresh() {
        print("🔄 Принудительное обновление кеша")
        addDebugInfo("🔄 Принудительное обновление кеша")
        DispatchQueue.main.async {
            self.lastLoadTime = nil
        }
        loadSessionsFromServer()
    }
    
    // MARK: - Auto-load on first access
    func ensureDataLoaded() {
        print("📊 Проверяем, нужна ли загрузка данных...")
        addDebugInfo("📊 Проверка необходимости загрузки данных")
        
        let currentState = """
        📊 Текущее состояние:
           - Количество сессий: \(sessions.count)
           - Загружается: \(isLoading)
           - Последняя загрузка: \(lastLoadTime?.description ?? "никогда")
           - Кеш валиден: \(isCacheValid())
        """
        print(currentState)
        addDebugInfo(currentState)
        
        if sessions.isEmpty && !isLoading && lastLoadTime == nil {
            print("📊 ➡️ Первичная загрузка данных сессий...")
            addDebugInfo("➡️ Начинаем первичную загрузку")
            loadSessionsFromServer()
        } else if !isCacheValid() && !isLoading {
            print("📊 ➡️ Обновление данных по истечении кеша...")
            addDebugInfo("➡️ Обновляем по истечении кеша")
            loadSessionsFromServer()
        } else {
            print("📊 ➡️ Данные актуальны, загрузка не требуется")
            addDebugInfo("➡️ Данные актуальны")
        }
    }
    
    // MARK: - Debug Methods
    private func addDebugInfo(_ info: String) {
        let timestamp = DateFormatter().string(from: Date())
        debugInfo.append("[\(timestamp)] \(info)")
        
        // Ограничиваем размер лога
        if debugInfo.count > 100 {
            debugInfo.removeFirst(50)
        }
    }
    
    func printDebugInfo() {
        print("📊 === ПОЛНАЯ DEBUG INFO - Session Manager ===")
        print("📊 Версия: БЕЗ @MainActor - Publishing changes исправлены")
        print("📊 Всего РЕАЛЬНЫХ сессий с сервера: \(sessions.count)")
        print("📊 Время последней загрузки: \(lastLoadTime?.description ?? "никогда")")
        print("📊 Ошибка: \(error ?? "нет")")
        print("📊 Загружается: \(isLoading)")
        print("📊 Кеш валиден: \(isCacheValid())")
        print("📊 Срок кеша: \(cacheExpirationTime) секунд")
        
        print("📊")
        print("📊 ДЕТАЛЬНЫЙ ЛОГ ОПЕРАЦИЙ:")
        for info in debugInfo.suffix(20) { // Показываем последние 20 записей
            print("📊 \(info)")
        }
        
        print("📊 ==========================================")
    }
    
    // MARK: - TEST METHODS для отладки
    #if DEBUG
    func addTestSession() {
        print("🧪 Добавляем тестовую сессию для отладки...")
        addDebugInfo("🧪 Добавляем тестовую сессию")
        let testSession = SessionData(
            id: Int.random(in: 1000...9999),
            date: Date(),
            moodLevel: .happy,
            note: "Тестовая сессия для отладки"
        )
        
        DispatchQueue.main.async {
            self.sessions.append(testSession)
        }
        NotificationCenter.default.post(name: .sessionDataUpdated, object: nil)
        print("🧪 Тестовая сессия добавлена: #\(testSession.id)")
        addDebugInfo("🧪 Тестовая сессия #\(testSession.id) добавлена")
    }
    
    func clearTestData() {
        print("🧪 Очищаем тестовые данные...")
        addDebugInfo("🧪 Очищаем тестовые данные")
        DispatchQueue.main.async {
            self.sessions.removeAll { $0.note.contains("Тестовая") }
        }
        NotificationCenter.default.post(name: .sessionDataUpdated, object: nil)
        print("🧪 Тестовые данные очищены")
    }
    
    func simulateNetworkError() {
        print("🧪 Симулируем сетевую ошибку...")
        addDebugInfo("🧪 Симулируем сетевую ошибку")
        DispatchQueue.main.async {
            self.isLoading = false
            self.error = "Симулированная ошибка сети (для тестирования)"
        }
        NotificationCenter.default.post(name: .sessionDataUpdated, object: nil)
    }
    
    func simulateEmptyResponse() {
        print("🧪 Симулируем пустой ответ сервера...")
        addDebugInfo("🧪 Симулируем пустой ответ")
        DispatchQueue.main.async {
            self.isLoading = false
            self.sessions.removeAll()
            self.error = nil
            self.lastLoadTime = Date()
        }
        NotificationCenter.default.post(name: .sessionDataUpdated, object: nil)
        print("🧪 Симуляция пустого ответа завершена")
    }
    #endif
}

// MARK: - Notification Name Extension (без изменений)
extension Notification.Name {
    static let sessionDataUpdated = Notification.Name("sessionDataUpdated")
}

// MARK: - ProfileSession Model для ProfileView (без изменений)
struct ProfileSession: Identifiable {
    let id: Int
    let date: Date
    let status: SessionStatus
    
    enum SessionStatus: Int {
        case bad = 2
        case good = 4
        
        @ViewBuilder var image: some View {
            switch self {
            case .bad:
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        )
                    
                    Image(systemName: "cloud.rain.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .frame(width: 40, height: 40)
            case .good:
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                        )
                    
                    Image(systemName: "sun.max.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                }
                .frame(width: 40, height: 40)
            }
        }
        
        var icon: String {
            switch self {
            case .good: return "sun.max.fill"
            case .bad: return "cloud.rain.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .good: return .orange
            case .bad: return .blue
            }
        }
        
        var description: String {
            switch self {
            case .good: return "Позитивная сессия"
            case .bad: return "Нужна поддержка"
            }
        }
    }
}
