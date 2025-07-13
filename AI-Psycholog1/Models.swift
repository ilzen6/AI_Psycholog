//
//  Models.swift
//  AI_Psycholog
//
//  Created by Илья Зенькович on 22.06.2025.
//

import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool = true
    let timestamp = Date()
}

struct UserProfile: Codable {
    var fullName: String = ""
    var email: String = ""
    var phone: String = ""
    var sessionBalance: Int = 3
    var avatarURL: String?
    var isDarkMode: Bool = false
    var saveHistory: Bool = false
}

struct SessionPackage: Identifiable {
    let id: Int
    let count: Int
    let price: Int
    let description: String
}
