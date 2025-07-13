//
//  MoodLevel.swift - Простые и красивые смайлики как на примере
//  AI_Psycholog
//
//  Чистый дизайн с простыми смайликами и красивыми цветами
//

import SwiftUI

enum MoodLevel: String, CaseIterable, Codable {
    case verySad = "very_sad"
    case sad = "sad"
    case neutral = "neutral"
    case happy = "happy"
    case veryHappy = "very_happy"
    
    @ViewBuilder var image: some View {
        switch self {
        case .verySad:
            // 😢 Очень грустный - темно-красный с плачущим лицом
            ZStack {
                Circle()
                    .fill(Color(red: 0.7, green: 0.2, blue: 0.2)) // Темно-красный
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                
                VStack(spacing: 4) {
                    // Простые белые глаза
                    HStack(spacing: 6) {
                        Ellipse()
                            .fill(Color.white)
                            .frame(width: 3, height: 4)
                        
                        Ellipse()
                            .fill(Color.white)
                            .frame(width: 3, height: 4)
                    }
                    
                    // ОЧЕНЬ грустный рот (большая перевернутая дуга)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addQuadCurve(to: CGPoint(x: 14, y: 0), control: CGPoint(x: 7, y: 5))
                    }
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 14, height: 5)
                    .scaleEffect(y: -1) // Переворачиваем для грустного рта
                    .offset(y: 2)
                }
            }
            
        case .sad:
            // 😞 Грустный - розово-красный
            ZStack {
                Circle()
                    .fill(Color(red: 0.9, green: 0.4, blue: 0.4)) // Розово-красный
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                
                VStack(spacing: 4) {
                    // Простые белые глаза
                    HStack(spacing: 6) {
                        Ellipse()
                            .fill(Color.white)
                            .frame(width: 3, height: 4)
                        
                        Ellipse()
                            .fill(Color.white)
                            .frame(width: 3, height: 4)
                    }
                    
                    // Грустный рот (перевернутая дуга)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addQuadCurve(to: CGPoint(x: 10, y: 0), control: CGPoint(x: 5, y: 3))
                    }
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 10, height: 3)
                    .scaleEffect(y: -1) // Переворачиваем для грустного рта
                    .offset(y: 2)
                }
            }
            
        case .neutral:
            // 😐 Нейтральный - оранжевый
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.6, blue: 0.3)) // Оранжевый
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                
                VStack(spacing: 4) {
                    // Простые белые глаза
                    HStack(spacing: 6) {
                        Ellipse()
                            .fill(Color.white)
                            .frame(width: 3, height: 4)
                        
                        Ellipse()
                            .fill(Color.white)
                            .frame(width: 3, height: 4)
                    }
                    
                    // Прямая линия рта
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white)
                        .frame(width: 8, height: 2)
                        .offset(y: 2)
                }
            }
            
        case .happy:
            // 😊 Счастливый - желтый
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.8, blue: 0.2)) // Ярко-желтый
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                
                VStack(spacing: 4) {
                    // Простые белые глаза
                    HStack(spacing: 6) {
                        Ellipse()
                            .fill(Color.white)
                            .frame(width: 3, height: 4)
                        
                        Ellipse()
                            .fill(Color.white)
                            .frame(width: 3, height: 4)
                    }
                    
                    // Счастливая улыбка
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addQuadCurve(to: CGPoint(x: 12, y: 0), control: CGPoint(x: 6, y: 4))
                    }
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 12, height: 4)
                    .offset(y: 2)
                }
            }
            
        case .veryHappy:
            // 😃 Очень счастливый - зеленый с большой улыбкой
            ZStack {
                Circle()
                    .fill(Color(red: 0.3, green: 0.7, blue: 0.5)) // Зеленый
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                
                VStack(spacing: 4) {
                    // Простые белые глаза
                    HStack(spacing: 6) {
                        Ellipse()
                            .fill(Color.white)
                            .frame(width: 3, height: 4)
                        
                        Ellipse()
                            .fill(Color.white)
                            .frame(width: 3, height: 4)
                    }
                    
                    // БОЛЬШАЯ счастливая улыбка
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addQuadCurve(to: CGPoint(x: 16, y: 0), control: CGPoint(x: 8, y: 6))
                    }
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 16, height: 6)
                    .offset(y: 2)
                }
            }
        }
    }
    
    var title: String {
        switch self {
        case .verySad: return "Ужасно"
        case .sad: return "Плохо"
        case .neutral: return "Нормально"
        case .happy: return "Хорошо"
        case .veryHappy: return "Отлично"
        }
    }
    
    var description: String {
        switch self {
        case .verySad: return "Ужасное настроение, нужна серьезная поддержка"
        case .sad: return "Грустное настроение, требуется внимание"
        case .neutral: return "Спокойное состояние, ни хорошо ни плохо"
        case .happy: return "Позитивные эмоции, день удался"
        case .veryHappy: return "Превосходное настроение, полон энергии"
        }
    }
    
    var score: Int {
        switch self {
        case .verySad: return 1
        case .sad: return 2
        case .neutral: return 3
        case .happy: return 4
        case .veryHappy: return 5
        }
    }
    
    var color: Color {
        switch self {
        case .verySad: return Color(red: 0.7, green: 0.2, blue: 0.2) // Темно-красный
        case .sad: return Color(red: 0.9, green: 0.4, blue: 0.4) // Розово-красный
        case .neutral: return Color(red: 1.0, green: 0.6, blue: 0.3) // Оранжевый
        case .happy: return Color(red: 1.0, green: 0.8, blue: 0.2) // Желтый
        case .veryHappy: return Color(red: 0.3, green: 0.7, blue: 0.5) // Зеленый
        }
    }
    
    // Инициализация по score
    static func from(score: Int) -> MoodLevel {
        switch score {
        case 1: return .verySad
        case 2: return .sad
        case 3: return .neutral
        case 4: return .happy
        case 5: return .veryHappy
        default: return .neutral
        }
    }
}

// MARK: - Time Filter для статистики (без изменений)
enum TimeFilter: CaseIterable {
    case week, month, year, all
    
    var title: String {
        switch self {
        case .week: return "Неделя"
        case .month: return "Месяц"
        case .year: return "Год"
        case .all: return "Все"
        }
    }
}
