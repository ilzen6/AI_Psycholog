//
//  WebView.swift - УПРОЩЕННОЕ ИСПРАВЛЕНИЕ для WebRTC
//  AI_Psycholog
//
//  ФОКУС: Только на WebRTC и медиа-разрешениях
//

import SwiftUI
import WebKit
import AVFoundation

struct WebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var viewModel: WebViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController.add(context.coordinator, name: "iOS")
        
        // КРИТИЧНО: Настройки для WebRTC и медиа
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        
        // Разрешаем JavaScript полностью
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        // Очищаем кеш
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        dataStore.removeData(ofTypes: dataTypes, modifiedSince: Date(timeIntervalSince1970: 0)) { }
        configuration.websiteDataStore = dataStore
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator // ВАЖНО для медиа-разрешений
        webView.allowsBackForwardNavigationGestures = true
        
        // Основные настройки
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = true
        
        webView.isUserInteractionEnabled = true
        webView.scrollView.isUserInteractionEnabled = true
        
        // Отключаем только зум
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.delegate = context.coordinator
        
        // УПРОЩЕННЫЙ скрипт для WebRTC
        let webrtcScript = """
        console.log('🎤 WebRTC support script loading...');
        
        // Viewport
        (function() {
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            var head = document.getElementsByTagName('head')[0];
            if (head) {
                var existing = head.querySelectorAll('meta[name="viewport"]');
                existing.forEach(function(tag) { tag.remove(); });
                head.insertBefore(meta, head.firstChild);
            }
        })();

        // Базовые стили
        var style = document.createElement('style');
        style.innerHTML = `
            html, body { overflow-x: hidden !important; max-width: 100% !important; }
            * { max-width: 100% !important; box-sizing: border-box !important; }
            input, textarea, button, select { font-size: 16px !important; }
            video, audio { max-width: 100% !important; height: auto !important; }
        `;
        document.head.appendChild(style);

        // Предотвращаем зум, разрешаем все остальное
        document.addEventListener('gesturestart', function(e) { e.preventDefault(); });
        document.addEventListener('gesturechange', function(e) { e.preventDefault(); });
        document.addEventListener('gestureend', function(e) { e.preventDefault(); });

        var lastTouchEnd = 0;
        document.addEventListener('touchend', function(e) {
            var now = Date.now();
            if (now - lastTouchEnd <= 300) {
                var target = e.target;
                if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || 
                    target.tagName === 'BUTTON' || target.tagName === 'A' ||
                    target.onclick || target.closest('button') || target.closest('a')) {
                    return; // Разрешаем для кнопок
                }
                e.preventDefault(); // Блокируем зум
            }
            lastTouchEnd = now;
        });

        // ОСНОВНОЕ: Отслеживаем WebRTC запросы
        if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
            var originalGetUserMedia = navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);
            navigator.mediaDevices.getUserMedia = function(constraints) {
                console.log('🎤 WebRTC getUserMedia called:', constraints);
                
                // Уведомляем iOS о запросе медиа
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.iOS) {
                    window.webkit.messageHandlers.iOS.postMessage({
                        type: 'webrtcMediaRequest',
                        constraints: constraints
                    });
                }
                
                return originalGetUserMedia(constraints)
                    .then(function(stream) {
                        console.log('✅ WebRTC stream obtained:', stream);
                        
                        // Уведомляем об успешном получении потока
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.iOS) {
                            window.webkit.messageHandlers.iOS.postMessage({
                                type: 'webrtcStreamObtained',
                                streamId: stream.id
                            });
                        }
                        
                        return stream;
                    })
                    .catch(function(error) {
                        console.log('❌ WebRTC error:', error);
                        
                        // Уведомляем об ошибке
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.iOS) {
                            window.webkit.messageHandlers.iOS.postMessage({
                                type: 'webrtcError',
                                error: error.toString()
                            });
                        }
                        
                        throw error;
                    });
            };
        }

        // Отслеживаем кнопки микрофона/звука
        document.addEventListener('click', function(e) {
            var target = e.target;
            var button = target.closest('button') || target.closest('[role="button"]');
            
            if (button) {
                var buttonText = (button.textContent || button.innerText || '').toLowerCase();
                var buttonClass = button.className || '';
                
                // Ищем кнопки связанные со звуком/микрофоном
                if (buttonText.includes('mic') || buttonText.includes('микрофон') ||
                    buttonText.includes('audio') || buttonText.includes('звук') ||
                    buttonText.includes('call') || buttonText.includes('звонок') ||
                    buttonClass.includes('mic') || buttonClass.includes('audio') ||
                    buttonClass.includes('call')) {
                    
                    console.log('🎤 Audio/Mic button clicked:', buttonText, buttonClass);
                    
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.iOS) {
                        window.webkit.messageHandlers.iOS.postMessage({
                            type: 'audioButtonClicked',
                            text: buttonText,
                            className: buttonClass
                        });
                    }
                }
            }
        }, true);

        console.log('✅ WebRTC support script loaded');
        """
        
        let userScript = WKUserScript(
            source: webrtcScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        configuration.userContentController.addUserScript(userScript)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        viewModel.setWebView(webView)
    }

    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, UIScrollViewDelegate, WKUIDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
            super.init()
            requestMicrophonePermission()
        }
        
        // КРИТИЧНО: Запрос разрешений
        private func requestMicrophonePermission() {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                print("🎤 Microphone permission: \(granted)")
            }
        }
        
        // ГЛАВНОЕ: Обработка WebRTC разрешений
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            
            print("🎤 WebRTC permission request for: \(origin.host), type: \(type.rawValue)")
            
            switch type {
            case .microphone:
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        print("🎤 Microphone access: \(granted)")
                        decisionHandler(granted ? .grant : .deny)
                    }
                }
            case .camera:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        print("📹 Camera access: \(granted)")
                        decisionHandler(granted ? .grant : .deny)
                    }
                }
            case .cameraAndMicrophone:
                AVCaptureDevice.requestAccess(for: .video) { videoGranted in
                    AVAudioSession.sharedInstance().requestRecordPermission { audioGranted in
                        DispatchQueue.main.async {
                            let granted = videoGranted && audioGranted
                            print("🎤📹 Camera+Mic access: \(granted)")
                            decisionHandler(granted ? .grant : .deny)
                        }
                    }
                }
            @unknown default:
                decisionHandler(.deny)
            }
        }
        
        func userContentController(_ userContentController: WKUserContentController,
                                 didReceive message: WKScriptMessage) {
            guard let dict = message.body as? [String: Any],
                  let type = dict["type"] as? String else { return }
            
            print("📱 WebView message: \(type)")
            
            switch type {
            case "webrtcMediaRequest":
                print("🎤 WebRTC media requested: \(dict)")
            case "webrtcStreamObtained":
                print("✅ WebRTC stream obtained: \(dict)")
            case "webrtcError":
                print("❌ WebRTC error: \(dict)")
                if let error = dict["error"] as? String {
                    showWebRTCError(error: error)
                }
            case "audioButtonClicked":
                print("🎤 Audio button clicked: \(dict)")
            default:
                DispatchQueue.main.async {
                    self.parent.viewModel.handleMessage(type: type, data: dict)
                }
            }
        }
        
        private func showWebRTCError(error: String) {
            DispatchQueue.main.async {
                print("🎤 WebRTC Error: \(error)")
                
                // Можно показать alert пользователю
                if error.contains("NotAllowedError") || error.contains("Permission") {
                    self.showPermissionAlert()
                }
            }
        }
        
        private func showPermissionAlert() {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                return
            }
            
            let alert = UIAlertController(
                title: "Разрешение на микрофон",
                message: "Для голосового общения с AI-психологом необходимо разрешить доступ к микрофону в настройках.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Настройки", style: .default) { _ in
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            })
            
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            topController.present(alert, animated: true)
        }
        
        // Контроль зума
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if scrollView.contentOffset.x != 0 {
                scrollView.contentOffset = CGPoint(x: 0, y: scrollView.contentOffset.y)
            }
            if scrollView.zoomScale != 1.0 {
                scrollView.setZoomScale(1.0, animated: false)
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ WebView loaded: \(webView.url?.absoluteString ?? "unknown")")
            
            DispatchQueue.main.async {
                webView.scrollView.setZoomScale(1.0, animated: false)
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            print("🔗 Navigation: \(url.absoluteString)")
            decisionHandler(.allow)
        }
    }
}
