//
//  PaymentWebView.swift
//  AI_Psycholog
//
//  Created by Илья Зенькович on 26.06.2025.
//

import SwiftUI
import WebKit

struct PaymentWebView: View {
    let paymentURL: URL
    let onSuccess: () -> Void
    let onCancel: () -> Void
    
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var canGoForward = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Индикатор загрузки
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "889E8C")))
                            .scaleEffect(1.5)
                        
                        Text("Загрузка платежной формы...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // WebView
                    PaymentWebViewWrapper(
                        url: paymentURL,
                        isLoading: $isLoading,
                        canGoBack: $canGoBack,
                        canGoForward: $canGoForward,
                        onSuccess: onSuccess,
                        onCancel: onCancel
                    )
                }
            }
            .navigationTitle("Оплата")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Отмена") {
                    onCancel()
                },
                trailing: HStack {
                    Button(action: {
                        // Обновить страницу
                        NotificationCenter.default.post(
                            name: NSNotification.Name("PaymentWebViewReload"),
                            object: nil
                        )
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            )
        }
    }
}

struct PaymentWebViewWrapper: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    let onSuccess: () -> Void
    let onCancel: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Настройки для лучшего отображения платежных форм
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // Настройки для избежания масштабирования
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = true
        
        // Подписываемся на уведомления
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.reloadWebView),
            name: NSNotification.Name("PaymentWebViewReload"),
            object: nil
        )
        
        context.coordinator.webView = webView
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: PaymentWebViewWrapper
        var webView: WKWebView?
        
        init(_ parent: PaymentWebViewWrapper) {
            self.parent = parent
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        @objc func reloadWebView() {
            webView?.reload()
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            
            // Проверяем URL на успешную оплату
            if let currentURL = webView.url?.absoluteString {
                // Здесь проверяем различные паттерны успешной оплаты
                if currentURL.contains("success") ||
                   currentURL.contains("payment_success") ||
                   currentURL.contains("completed") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.parent.onSuccess()
                    }
                } else if currentURL.contains("cancel") ||
                          currentURL.contains("payment_cancel") ||
                          currentURL.contains("error") {
                    self.parent.onCancel()
                }
            }
            
            // Добавляем CSS для предотвращения масштабирования
            let disableZoomScript = """
                var meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                var head = document.getElementsByTagName('head')[0];
                head.appendChild(meta);
                
                document.body.style.webkitUserSelect = 'none';
                document.body.style.webkitTouchCallout = 'none';
            """
            
            webView.evaluateJavaScript(disableZoomScript)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            print("Payment WebView failed to load: \(error)")
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            // Проверяем deep links для банковских приложений
            if let url = navigationAction.request.url,
               let scheme = url.scheme,
               !["http", "https"].contains(scheme) {
                
                // Открываем банковское приложение
                UIApplication.shared.open(url) { success in
                    if !success {
                        // Если не удалось открыть приложение, продолжаем в WebView
                        print("Failed to open banking app with URL: \(url)")
                    }
                }
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
    }
}

// Обновляем PaymentView для использования внутреннего WebView
extension PaymentView {
    @ViewBuilder
    func paymentWebViewSheet() -> some View {
        // Этот метод можно использовать для показа WebView как sheet
        EmptyView()
    }
}
