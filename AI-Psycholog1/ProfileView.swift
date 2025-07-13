//
//  ProfileView.swift - ПОЛНОСТЬЮ ИСПРАВЛЕННАЯ версия БЕЗ onChange ошибок
//  AI_Psycholog
//
//  КРИТИЧНО: УБРАНЫ ВСЕ onChange - заменены на кнопки
//

import SwiftUI
import WebKit
struct ProfileView: View {
    @ObservedObject var webViewModel: WebViewModel
    @StateObject private var sessionManager = SessionDataManager.shared
    @State private var profile = UserProfile()
    @State private var showingImagePicker = false
    @State private var avatarImage: UIImage?
    @State private var selectedSegment = 0
    @State private var localSessionBalance = 0
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("saveHistory") private var saveHistory = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Секция аватара и имени
                VStack(spacing: 16) {
                    if let avatarImage = avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    Text(profile.fullName.isEmpty ? "Пользователь" : profile.fullName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    // Баланс сессий
                    HStack {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(Color(hex: "889E8C"))
                        Text("Доступно сессий: \(profile.sessionBalance + localSessionBalance)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        NotificationCenter.default.post(name: .showPayment, object: nil)
                    }) {
                        Text("Купить сессии")
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(Color(hex: "889E8C"))
                            .cornerRadius(20)
                    }
                }
                .padding(.vertical, 20)
                
                // Сегментированный контроль
                Picker("", selection: $selectedSegment) {
                    Text("Сессии").tag(0)
                    Text("Достижения").tag(1)
                    Text("Настройки").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Контент в зависимости от выбранного сегмента
                ScrollView {
                    switch selectedSegment {
                    case 0:
                        fixedSessionsSection
                    case 1:
                        achievementsSection
                    case 2:
                        settingsSection
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationBarHidden(true)
            .background(Color(UIColor.systemBackground))
            .onAppear {
                setupProfileView()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SessionBalanceUpdated"))) { _ in
                DispatchQueue.main.async {
                    loadLocalSessionBalance()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .sessionDataUpdated)) { _ in
                DispatchQueue.main.async {
                    handleSessionDataUpdate()
                }
            }
        }
    }
    
    private func setupProfileView() {
        loadProfile()
        updateTheme(isDark: isDarkMode)
        loadLocalSessionBalance()
        
        print("📱 ProfileView появился, запускаем загрузку данных...")
        sessionManager.ensureDataLoaded()
    }
    
    private func handleSessionDataUpdate() {
        print("📱 ProfileView: Получено уведомление об обновлении сессий")
        print("📱 ProfileView: Текущее количество сессий: \(sessionManager.sessions.count)")
    }
    
    // MARK: - ИСПРАВЛЕННАЯ секция сессий без баллов и времени
    private var fixedSessionsSection: some View {
        VStack(spacing: 16) {
            // Статистика использования - РЕАЛЬНЫЕ ДАННЫЕ
            VStack(spacing: 12) {
                HStack {
                    Text("📊 История сессий с AI-психологом")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Кнопка принудительного обновления
                    Button(action: {
                        refreshSessionData()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                            Text("Обновить")
                                .font(.caption)
                        }
                        .foregroundColor(Color(hex: "889E8C"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "889E8C").opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    #if DEBUG
                    // DEBUG кнопки
                    Menu("DEBUG") {
                        Button("Показать отладку") {
                            sessionManager.printDebugInfo()
                        }
                        Button("Добавить тест") {
                            sessionManager.addTestSession()
                        }
                        Button("Очистить тесты") {
                            sessionManager.clearTestData()
                        }
                        Button("Симуляция ошибки") {
                            sessionManager.simulateNetworkError()
                        }
                        Button("Симуляция пустого ответа") {
                            sessionManager.simulateEmptyResponse()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                    #endif
                }
                
                HStack(spacing: 16) {
                    FixedStatisticCard(
                        title: "Всего сессий",
                        value: "\(sessionManager.sessions.count)",
                        icon: "message.circle.fill",
                        color: .blue
                    )
                    
                    FixedStatisticCard(
                        title: "Дней подряд",
                        value: "\(sessionManager.getStreakDays())",
                        icon: "flame.fill",
                        color: .orange
                    )
                }
                
                HStack(spacing: 16) {
                    FixedStatisticCard(
                        title: "Успешных сессий",
                        value: "\(getSuccessfulSessionsCount())",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    FixedStatisticCard(
                        title: "Этот месяц",
                        value: "\(sessionManager.getSessionsThisMonth())",
                        icon: "calendar",
                        color: .purple
                    )
                }
            }
            
            // ИСПРАВЛЕННАЯ секция истории сессий БЕЗ БАЛЛОВ И ВРЕМЕНИ
            VStack(spacing: 12) {
                HStack {
                    Text("🕐 Детальная история")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Статус загрузки
                    if sessionManager.isLoading {
                        HStack(spacing: 4) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "889E8C")))
                                .scaleEffect(0.7)
                            Text("Загрузка...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("(\(sessionManager.sessions.count) всего)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // ИСПРАВЛЕННАЯ обработка состояний
                if sessionManager.isLoading {
                    FixedLoadingView()
                } else if let error = sessionManager.error {
                    FixedErrorView(
                        error: error,
                        onRetry: {
                            print("📱 ProfileView: Повторная попытка загрузки")
                            sessionManager.refreshData()
                        },
                        onDebug: {
                            sessionManager.printDebugInfo()
                        }
                    )
                } else if sessionManager.sessions.isEmpty {
                    FixedEmptyStateView(
                        onStartSession: {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("SwitchToChat"),
                                object: nil
                            )
                        },
                        onRefresh: {
                            sessionManager.refreshData()
                        }
                    )
                } else {
                    // ИСПРАВЛЕННЫЙ список сессий БЕЗ БАЛЛОВ И ВРЕМЕНИ
                    let profileSessions = sessionManager.getSessionsForProfile().prefix(15)
                    
                    ForEach(Array(profileSessions), id: \.id) { session in
                        FixedSessionCard(session: session)
                    }
                    
                    if sessionManager.sessions.count > 15 {
                        Text("Показаны последние 15 из \(sessionManager.sessions.count) сессий")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    
                    // Информация о последнем обновлении
                    if let lastUpdate = sessionManager.lastLoadTime {
                        Text("Обновлено: \(lastUpdate, style: .time)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            checkSessionData()
        }
    }
    
    private var achievementsSection: some View {
        VStack(spacing: 16) {
            Text("🏆 Ваши достижения")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                AchievementCard(
                    title: "Новичок",
                    description: "Первая сессия",
                    icon: "star.fill",
                    isUnlocked: sessionManager.sessions.count >= 1,
                    color: .yellow
                )
                
                AchievementCard(
                    title: "Постоянство",
                    description: "7 дней подряд",
                    icon: "calendar",
                    isUnlocked: sessionManager.getStreakDays() >= 7,
                    color: .blue
                )
                
                AchievementCard(
                    title: "Исследователь",
                    description: "10 сессий",
                    icon: "leaf.circle",
                    isUnlocked: sessionManager.sessions.count >= 10,
                    color: .green
                )
                
                AchievementCard(
                    title: "Мастер спокойствия",
                    description: "30 сессий",
                    icon: "hands.sparkles",
                    isUnlocked: sessionManager.sessions.count >= 30,
                    color: .purple
                )
                
                AchievementCard(
                    title: "Позитивность",
                    description: "Много хороших сессий",
                    icon: "sun.max.fill",
                    isUnlocked: getSuccessfulSessionsCount() >= 5,
                    color: .orange
                )
                
                AchievementCard(
                    title: "Терпение",
                    description: "30 дней подряд",
                    icon: "infinity",
                    isUnlocked: sessionManager.getStreakDays() >= 30,
                    color: .pink
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private var settingsSection: some View {
        VStack(spacing: 16) {
            // КРИТИЧНО: УБРАН onChange - заменен на кнопку
            HStack {
                Label("Темная тема", systemImage: "moon.fill")
                Spacer()
                Button(action: {
                    DispatchQueue.main.async {
                        isDarkMode.toggle()
                        updateTheme(isDark: isDarkMode)
                    }
                }) {
                    Image(systemName: isDarkMode ? "checkmark.square" : "square")
                        .foregroundColor(Color(hex: "889E8C"))
                        .font(.title2)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            
            // КРИТИЧНО: УБРАН onChange - заменен на кнопку
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Сохранять историю", systemImage: "clock.arrow.circlepath")
                    Spacer()
                    Button(action: {
                        DispatchQueue.main.async {
                            saveHistory.toggle()
                            updateHistorySetting(save: saveHistory)
                        }
                    }) {
                        Image(systemName: saveHistory ? "checkmark.square" : "square")
                            .foregroundColor(Color(hex: "889E8C"))
                            .font(.title2)
                    }
                }
                
                Text(saveHistory ?
                     "Ваши диалоги сохраняются для анализа эмоционального состояния и отслеживания прогресса терапии" :
                     "Диалоги удаляются после каждой сессии для максимальной конфиденциальности")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 30)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            
            #if DEBUG
            VStack(spacing: 12) {
                Button {
                    resetOnboardingFlow()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Сбросить онбординг (DEBUG)")
                    }
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                }
                
                Button {
                    sessionManager.printDebugInfo()
                } label: {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Показать отладочную информацию")
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                }
                
                Button {
                    sessionManager.refreshData()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Принудительно загрузить сессии")
                    }
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                }
            }
            #endif
            
            
            
            // Кнопка выхода
            Button(action: logout) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Выйти из аккаунта")
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func refreshSessionData() {
        print("📱 ProfileView: Пользователь нажал обновить")
        sessionManager.refreshData()
    }
    
    private func checkSessionData() {
        print("📱 ProfileView: Секция сессий появилась")
        print("📱 ProfileView: Состояние SessionManager:")
        print("   - Сессий: \(sessionManager.sessions.count)")
        print("   - Загружается: \(sessionManager.isLoading)")
        print("   - Ошибка: \(sessionManager.error ?? "нет")")
        
        // Принудительно запускаем загрузку если данных нет
        if sessionManager.sessions.isEmpty && !sessionManager.isLoading {
            print("📱 ProfileView: Данных нет, запускаем загрузку...")
            sessionManager.refreshData()
        }
    }
    
    func loadProfile() {
        APIManager.shared.getProfile { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profileData):
                    self.profile = profileData
                    if let avatarURL = profileData.avatarURL {
                        self.loadAvatarImage(from: avatarURL)
                    }
                    print("📱 ProfileView: Профиль загружен, баланс сессий: \(profileData.sessionBalance)")
                case .failure(let error):
                    print("❌ ProfileView: Ошибка загрузки профиля: \(error)")
                }
            }
        }
    }
    
    func loadAvatarImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.avatarImage = image
                }
            }
        }.resume()
    }

    func updateTheme(isDark: Bool) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = isDark ? .dark : .light
            }
        }
        
        let script = """
        if (typeof window.changeWebViewTheme === 'function') {
            window.changeWebViewTheme(\(isDark));
        }
        """
        
        webViewModel.evaluateJavaScript(script)
    }
    
    func updateHistorySetting(save: Bool) {
        let script = """
        if (window.updateHistorySetting) {
            window.updateHistorySetting(\(save));
        }
        """
        webViewModel.evaluateJavaScript(script)
        
        print("История будет \(save ? "сохраняться" : "не сохраняться")")
    }
    
    func loadLocalSessionBalance() {
        let balance = UserDefaults.standard.integer(forKey: "localSessionBalance")
        localSessionBalance = balance
        print("📱 ProfileView: Локальный баланс сессий: \(balance)")
    }
    
    // НОВАЯ функция для подсчета успешных сессий (вместо среднего настроения)
    private func getSuccessfulSessionsCount() -> Int {
        return sessionManager.sessions.filter { session in
            session.moodLevel.score >= 4 // Считаем "happy" и "veryHappy" как успешные
        }.count
    }
    
    #if DEBUG
    private func resetOnboardingFlow() {
        print("🔄 Сброс онбординга и дисклеймера")
        
        UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
        UserDefaults.standard.set(false, forKey: "hasAcceptedDisclaimer")
        UserDefaults.standard.synchronize()
        
        print("🔄 Состояние после сброса:")
        print("   hasSeenOnboarding: \(UserDefaults.standard.bool(forKey: "hasSeenOnboarding"))")
        print("   hasAcceptedDisclaimer: \(UserDefaults.standard.bool(forKey: "hasAcceptedDisclaimer"))")
        
        showRestartAlert()
    }

    private func showRestartAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        let alert = UIAlertController(
            title: "Сброс выполнен",
            message: "Для применения изменений перезапустите приложение",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Перезапустить", style: .default) { _ in
            exit(0)
        })
        
        alert.addAction(UIAlertAction(title: "Позже", style: .cancel))
        
        if let rootViewController = window.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    #endif
    
    private func clearWebViewData() {
        print("📱 ProfileView: Очищаем данные WebView...")
        
        // Очищаем куки WebView
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        
        dataStore.removeData(ofTypes: dataTypes, modifiedSince: Date(timeIntervalSince1970: 0)) {
            print("📱 ProfileView: WebView данные очищены")
        }
        
        // Очищаем куки HTTP
        if let url = URL(string: "https://w-psycholog.com") {
            let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
                print("📱 ProfileView: Удален куки: \(cookie.name)")
            }
            print("📱 ProfileView: HTTP куки очищены (\(cookies.count) шт.)")
        }
    }

    // MARK: - Logout Function
    func logout() {
        print("📱 ProfileView: Начинаем процесс выхода из аккаунта")
        
        DispatchQueue.main.async {
            // Очищаем данные пользователя
            KeychainManager.shared.clearCredentials()
            UserDefaults.standard.removeObject(forKey: "userProfile")
            UserDefaults.standard.removeObject(forKey: "lastUsername")
            UserDefaults.standard.removeObject(forKey: "localSessionBalance")
            
            // Очищаем сессии
            self.sessionManager.clearLocalData()
            
            // Очищаем WebView данные
            self.clearWebViewData()
            
            // КРИТИЧНО: Отправляем уведомление о выходе
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
            
            print("📱 ProfileView: Выход выполнен, уведомление отправлено")
        }
    }
}

// MARK: - Supporting Views (БЕЗ ИЗМЕНЕНИЙ)

struct FixedStatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct FixedSessionCard: View {
    let session: ProfileSession
    
    var body: some View {
        HStack(spacing: 16) {
            session.status.image
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Сессия #\(session.id)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(session.date, format: .dateTime.day().month().year())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(session.status.description)
                    .font(.caption)
                    .foregroundColor(session.status.color)
                    .padding(.top, 2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct FixedLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "889E8C")))
                .scaleEffect(1.5)
            
            VStack(spacing: 8) {
                Text("Загружаем историю сессий...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct FixedErrorView: View {
    let error: String
    let onRetry: () -> Void
    let onDebug: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                Text("Проблема с загрузкой")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(error)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button("Повторить попытку") {
                    onRetry()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "889E8C"))
                .cornerRadius(12)
                
                #if DEBUG
                Button("Показать отладочную информацию") {
                    onDebug()
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                #endif
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct FixedEmptyStateView: View {
    let onStartSession: () -> Void
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "message.badge")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text("История сессий пуста")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Начните общение с AI-психологом, и здесь появится история ваших диалогов")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button("Начать первую сессию") {
                    onStartSession()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "889E8C"),
                            Color(hex: "6B7F6F")
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                
                Button("Обновить данные") {
                    onRefresh()
                }
                .foregroundColor(Color(hex: "889E8C"))
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: "889E8C").opacity(0.1))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct AchievementCard: View {
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? color : Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? .white : .gray)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if !isUnlocked {
                Text("Заблокировано")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}
