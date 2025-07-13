//
//  ApplePayButton.swift
//  AI_Psycholog
//
//  Created by Илья Зенькович on 22.06.2025.
//

import SwiftUI
import PassKit

struct ApplePayButton: UIViewRepresentable {
    let action: () -> Void
    
    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.pay), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func pay() {
            action()
        }
    }
}

// Apple Pay Coordinator
class ApplePayCoordinator: NSObject, PKPaymentAuthorizationControllerDelegate {
    static let shared = ApplePayCoordinator()
    var completion: ((Bool) -> Void)?
    
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                      didAuthorizePayment payment: PKPayment,
                                      handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        // Обработка платежа
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        self.completion?(true)
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss()
    }
}
