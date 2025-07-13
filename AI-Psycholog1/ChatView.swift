//
//  ChatView.swift - ПОЛНОСТЬЮ ИСПРАВЛЕННАЯ версия БЕЗ Publishing changes ошибок
//  AI_Psycholog
//
//  КРИТИЧНО: ВСЕ обновления State через DispatchQueue.main.async
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var webViewModel: WebViewModel
    @State private var showingShareSheet = false
    @State private var selectedMessage: ChatMessage?
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var hasCheckedSession = false
    @State private var isWebPageLoaded = false
    @State private var webViewKey = UUID()
    @State private var isLoading = true
    @State private var loadingText = "Подключение..."
    @State private var themeApplied = false
    @State private var showPaymentWebView = false
    @State private var paymentURL: URL?
    
    var body: some View {
        ZStack {
            WebView(
                url: URL(string: "https://w-psycholog.com/chat")!,
                viewModel: webViewModel
            )
            .id(webViewKey)
            .opacity(isLoading ? 0 : 1)
            .animation(.easeInOut(duration: 0.5), value: isLoading)
            
            // Улучшенный экран загрузки
            if isLoading {
                ZStack {
                    Color(hex: "A5BDA9")
                        .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        // Анимированная иконка мозга
                        Image(systemName: "brain")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .scaleEffect(themeApplied ? 1.2 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true),
                                value: isLoading
                            )
                        
                        // Текст загрузки
                        Text(loadingText)
                            .font(.title2)
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                        
                        // Улучшенный индикатор прогресса
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            
                            // Прогресс-бар для этапов загрузки
                            ProgressView(value: getLoadingProgress(), total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                                .frame(width: 200)
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true) // Скрываем стандартную навигацию
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [selectedMessage?.text ?? ""])
        }
        .sheet(isPresented: $showPaymentWebView) {
            if let url = paymentURL {
                PaymentWebView(
                    paymentURL: url,
                    onSuccess: {
                        DispatchQueue.main.async {
                            self.showPaymentWebView = false
                            self.paymentURL = nil
                        }
                    },
                    onCancel: {
                        DispatchQueue.main.async {
                            self.showPaymentWebView = false
                            self.paymentURL = nil
                        }
                    }
                )
            }
        }
        .onAppear {
            setupMessageHandlers()
            checkSessionOnAppear()
            startEnhancedLoadingSequence()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidLogout)) { _ in
            DispatchQueue.main.async {
                handleUserLogout()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidLogin)) { _ in
            DispatchQueue.main.async {
                handleUserLogin()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPaymentInApp"))) { notification in
            DispatchQueue.main.async {
                handlePaymentNotification(notification)
            }
        }
    }
    
    private func checkSessionOnAppear() {
        if !hasCheckedSession {
            checkSession()
            hasCheckedSession = true
        }
    }
    
    private func handleUserLogout() {
        resetLoadingState()
        webViewKey = UUID()
    }
    
    private func handleUserLogin() {
        resetLoadingState()
        webViewKey = UUID()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            startEnhancedLoadingSequence()
        }
    }
    
    private func handlePaymentNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let urlString = userInfo["paymentURL"] as? String,
           let url = URL(string: urlString) {
            paymentURL = url
            showPaymentWebView = true
        }
    }
    
    private func resetLoadingState() {
        isLoading = true
        loadingText = "Подключение..."
        themeApplied = false
    }
    
    private func getLoadingProgress() -> Double {
        switch loadingText {
        case "Подключение...": return 0.2
        case "Применение темы...": return 0.5
        case "Настройка интерфейса...": return 0.7
        case "Авторизация...": return 0.9
        case "Готово!": return 1.0
        default: return 0.1
        }
    }
    
    private func startEnhancedLoadingSequence() {
        loadingText = "Подключение..."
        
        // Этап 1: Ожидание загрузки WebView
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.loadingText = "Применение темы..."
            
            // Применяем тему сразу после загрузки
            self.applyThemeToWebView()
            self.themeApplied = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.loadingText = "Настройка интерфейса..."
                self.configureWebViewSettings()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.loadingText = "Авторизация..."
                    self.performSilentLogin()
                }
            }
        }
    }
    
    private func configureWebViewSettings() {
        let configScript = """
        // Отключаем масштабирование и горизонтальную прокрутку
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        var head = document.getElementsByTagName('head')[0];
        if (head) {
            head.appendChild(meta);
        }
        
        // Добавляем стили для работающего чата
        var style = document.createElement('style');
        style.innerHTML = `
            html, body {
                overflow-x: hidden !important;
                width: 100% !important;
                max-width: 100% !important;
                -webkit-text-size-adjust: 100% !important;
                touch-action: manipulation !important;
            }
            
            * {
                max-width: 100% !important;
                box-sizing: border-box !important;
            }
            
            input, textarea, select, button {
                font-size: 16px !important;
                pointer-events: auto !important;
                touch-action: manipulation !important;
            }
            
            button, [role="button"], .btn, .button,
            input[type="submit"], input[type="button"] {
                pointer-events: auto !important;
                cursor: pointer !important;
            }
            
            a, [role="link"] {
                pointer-events: auto !important;
            }
            
            .chat-container, .message-container, .chat-input-container {
                width: 100% !important;
                max-width: 100% !important;
                overflow-x: hidden !important;
                box-sizing: border-box !important;
                pointer-events: auto !important;
            }
            
            .chat-input, [data-chat-input], .message-input {
                pointer-events: auto !important;
                touch-action: manipulation !important;
            }
            
            /* Скрываем горизонтальные полосы прокрутки */
            ::-webkit-scrollbar:horizontal {
                display: none !important;
            }
        `;
        document.head.appendChild(style);
        
        console.log('WebView settings configured successfully');
        """
        
        webViewModel.evaluateJavaScript(configScript)
    }
    
    private func performSilentLogin() {
        guard let credentials = KeychainManager.shared.getCredentials() else {
            finishLoading()
            return
        }
        
        let enhancedLoginScript = """
        console.log('Starting enhanced silent login...');
        
        function enhancedSilentLogin() {
            const username = '\(credentials.username.escapedForJavaScript)';
            const password = '\(credentials.password.escapedForJavaScript)';
            
            console.log('Attempting login with username:', username);
            
            function findLoginFields() {
                let usernameField = 
                    document.querySelector('input[name="login"]') ||
                    document.querySelector('input[name="username"]') ||
                    document.querySelector('input[name="user"]') ||
                    document.querySelector('input[name="email"]') ||
                    document.querySelector('input[type="text"]') ||
                    document.querySelector('input[type="email"]') ||
                    document.querySelector('input[placeholder*="логин" i]') ||
                    document.querySelector('input[placeholder*="login" i]') ||
                    document.querySelector('input[placeholder*="пользовател" i]');
                
                let passwordField = 
                    document.querySelector('input[name="password"]') ||
                    document.querySelector('input[type="password"]') ||
                    document.querySelector('input[placeholder*="пароль" i]') ||
                    document.querySelector('input[placeholder*="password" i]');
                
                return { usernameField, passwordField };
            }
            
            function findSubmitButton(form) {
                let submitButton = null;
                
                submitButton = document.querySelector('button[type="submit"]') ||
                              document.querySelector('input[type="submit"]');
                
                if (!submitButton) {
                    const buttons = document.querySelectorAll('button, input[type="button"], a');
                    for (let btn of buttons) {
                        const text = (btn.textContent || btn.value || btn.innerText || '').toLowerCase().trim();
                        if (text === 'войти' || text === 'login' || text === 'вход' || 
                            text === 'sign in' || text === 'enter' || text === 'log in') {
                            submitButton = btn;
                            break;
                        }
                    }
                }
                
                if (!submitButton && form) {
                    submitButton = form.querySelector('button:not([type="button"]):not([type="reset"])') ||
                                  form.querySelector('input[type="submit"]') ||
                                  form.querySelector('button');
                }
                
                return submitButton;
            }
            
            function performLogin() {
                const { usernameField, passwordField } = findLoginFields();
                
                if (!usernameField || !passwordField) {
                    console.log('Login fields not found, retrying...');
                    setTimeout(performLogin, 1000);
                    return;
                }
                
                console.log('Found login fields, filling credentials...');
                
                usernameField.value = '';
                passwordField.value = '';
                usernameField.value = username;
                passwordField.value = password;
                
                const events = ['input', 'change', 'blur', 'focus', 'keyup'];
                events.forEach(eventType => {
                    const event = new Event(eventType, { bubbles: true, cancelable: true });
                    usernameField.dispatchEvent(event);
                    passwordField.dispatchEvent(event);
                });
                
                setTimeout(() => {
                    const form = usernameField.closest('form') || passwordField.closest('form');
                    const submitButton = findSubmitButton(form);
                    
                    console.log('Attempting to submit form...');
                    
                    if (submitButton) {
                        console.log('Found submit button, clicking...');
                        
                        if (submitButton.disabled) {
                            submitButton.disabled = false;
                        }
                        
                        try {
                            submitButton.click();
                        } catch (e) {
                            const clickEvent = new MouseEvent('click', {
                                view: window,
                                bubbles: true,
                                cancelable: true
                            });
                            submitButton.dispatchEvent(clickEvent);
                        }
                    } else {
                        console.log('Submit button not found, trying form submit...');
                        
                        if (form) {
                            try {
                                form.submit();
                            } catch (e) {
                                console.log('Form submit failed:', e);
                            }
                        }
                        
                        const enterEvent = new KeyboardEvent('keydown', {
                            key: 'Enter',
                            code: 'Enter',
                            keyCode: 13,
                            which: 13,
                            bubbles: true,
                            cancelable: true
                        });
                        passwordField.dispatchEvent(enterEvent);
                    }
                    
                }, 800);
            }
            
            function checkAuthStatus() {
                const hasAuthCookie = document.cookie.includes('auth') || 
                                     document.cookie.includes('session') ||
                                     document.cookie.includes('token');
                
                const hasUserElements = document.querySelector('.user-profile, .logout, .dashboard, .user-menu, [data-user]');
                const noLoginForm = !document.querySelector('input[type="password"]');
                
                if (hasAuthCookie || hasUserElements || noLoginForm) {
                    console.log('User appears to be already logged in');
                    return true;
                }
                
                return false;
            }
            
            if (checkAuthStatus()) {
                console.log('Already authenticated');
                return;
            }
            
            if (document.readyState !== 'complete') {
                window.addEventListener('load', () => {
                    setTimeout(performLogin, 500);
                });
            } else {
                setTimeout(performLogin, 500);
            }
        }
        
        enhancedSilentLogin();
        """
        
        webViewModel.evaluateJavaScript(enhancedLoginScript)
        
        // Увеличиваем время ожидания для завершения авторизации
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            finishLoading()
        }
    }
    
    private func finishLoading() {
        loadingText = "Готово!"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isLoading = false
            }
        }
    }
    
    func applyThemeToWebView() {
        let script = """
        function applyWebViewTheme(isDark) {
            // Удаляем предыдущие стили темы
            var existingStyle = document.getElementById('ios-webview-theme');
            if (existingStyle) {
                existingStyle.remove();
            }
            
            var style = document.createElement('style');
            style.id = 'ios-webview-theme';
            
            if (isDark) {
                style.innerHTML = `
                    html {
                        filter: invert(1) hue-rotate(180deg) brightness(1.1) contrast(0.9) !important;
                        -webkit-filter: invert(1) hue-rotate(180deg) brightness(1.1) contrast(0.9) !important;
                        transition: filter 0.3s ease !important;
                    }
                    
                    img, video, iframe, svg, canvas, 
                    [style*="background-image"],
                    .image, .photo, .avatar, .logo {
                        filter: invert(1) hue-rotate(180deg) !important;
                        -webkit-filter: invert(1) hue-rotate(180deg) !important;
                        transition: filter 0.3s ease !important;
                    }
                    
                    .emoji, [data-emoji], .icon {
                        filter: invert(1) hue-rotate(180deg) !important;
                        -webkit-filter: invert(1) hue-rotate(180deg) !important;
                    }
                `;
            } else {
                style.innerHTML = `
                    html {
                        filter: none !important;
                        -webkit-filter: none !important;
                        transition: filter 0.3s ease !important;
                    }
                    
                    img, video, iframe, svg, canvas {
                        filter: none !important;
                        -webkit-filter: none !important;
                        transition: filter 0.3s ease !important;
                    }
                `;
            }
            
            document.head.appendChild(style);
            
            // Применяем тему немедленно
            document.documentElement.style.opacity = '0';
            setTimeout(function() {
                document.documentElement.style.opacity = '1';
            }, 100);
        }
        
        // Применяем тему сразу
        applyWebViewTheme(\(isDarkMode));
        window.changeWebViewTheme = applyWebViewTheme;
        
        // Функция для обновления настройки истории
        window.updateHistorySetting = function(saveHistory) {
            console.log('History setting updated:', saveHistory);
        };
        
        // Функция для обработки платежей в приложении
        window.processInAppPayment = function(paymentData) {
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.iOS) {
                window.webkit.messageHandlers.iOS.postMessage({
                    type: 'inAppPayment',
                    data: paymentData
                });
            }
        };
        
        console.log('Theme applied successfully');
        """
        
        webViewModel.evaluateJavaScript(script)
    }
    
    // Добавьте эти обработчики в функцию setupMessageHandlers() в ChatView.swift

    func setupMessageHandlers() {
        webViewModel.messageHandlers["copyText"] = { data in
            if let text = data["text"] as? String {
                UIPasteboard.general.string = text
            }
        }
        
        webViewModel.messageHandlers["shareText"] = { data in
            if let text = data["text"] as? String {
                DispatchQueue.main.async {
                    self.selectedMessage = ChatMessage(text: text)
                    self.showingShareSheet = true
                }
            }
        }
        
        // НОВЫЙ: Обработчик для отладки звонков
        webViewModel.messageHandlers["debugCallElements"] = { data in
            print("🔍 ChatView: Получены элементы звонков для отладки")
            if let elements = data["elements"] as? [[String: Any]] {
                print("🔍 Найдено элементов звонков: \(elements.count)")
                elements.forEach { element in
                    print("🔍 - \(element)")
                }
            }
        }
        
        // Добавляем обработчик для платежей в приложении
        webViewModel.messageHandlers["inAppPayment"] = { data in
            if let paymentData = data["data"] as? [String: Any],
               let urlString = paymentData["paymentURL"] as? String {
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowPaymentInApp"),
                    object: nil,
                    userInfo: ["paymentURL": urlString]
                )
            }
        }
        
        // Обработчик завершения сессии с настроением
        webViewModel.messageHandlers["sessionCompleted"] = { data in
            if let moodString = data["mood"] as? String,
               let note = data["note"] as? String {
                
                let moodLevel: MoodLevel = moodString == "good" ? .happy : .sad
                
                SessionDataManager.shared.addSession(moodLevel: moodLevel, note: note)
                
                print("✅ Создана запись настроения: \(moodLevel.title) - \(note)")
            }
        }
    }

    // НОВЫЙ: Добавьте этот метод в ChatView для отладки
    func debugCallElements() {
        print("🔍 ChatView: Запуск отладки элементов звонков")
        webViewModel.debugWebViewContent()
    }
    func checkSession() {
        APIManager.shared.getProfile { result in
            switch result {
            case .success(let profile):
                if profile.sessionBalance <= 0 {
                    NotificationCenter.default.post(name: .showPayment, object: nil)
                }
            case .failure:
                NotificationCenter.default.post(name: .showPayment, object: nil)
            }
        }
    }
}
