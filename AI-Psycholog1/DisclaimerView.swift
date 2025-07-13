//
//  DisclaimerView.swift - ОКОНЧАТЕЛЬНОЕ ИСПРАВЛЕНИЕ
//  AI_Psycholog
//
//  КРИТИЧНО: Простая структура без сложной логики
//

import SwiftUI

struct DisclaimerView: View {
    @Binding var isPresented: Bool
    @AppStorage("hasAcceptedDisclaimer") private var hasAcceptedDisclaimer = false
    let onAccepted: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Заголовок с иконкой
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Важная информация")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Основной текст дисклеймера
                    VStack(spacing: 20) {
                        DisclaimerCard(
                            icon: "brain",
                            title: "AI-консультант",
                            description: "Данное приложение использует технологии искусственного интеллекта для предоставления эмоциональной поддержки и общих рекомендаций по улучшению психологического благополучия."
                        )
                        
                        DisclaimerCard(
                            icon: "stethoscope",
                            title: "Не медицинский диагноз",
                            description: "Приложение НЕ предоставляет медицинские диагнозы, лечение или профессиональную психотерапию. Это инструмент поддержки и самопомощи.",
                            isWarning: true
                        )
                        
                        DisclaimerCard(
                            icon: "person.badge.plus",
                            title: "Обратитесь к специалисту",
                            description: "При серьезных психологических проблемах, суицидальных мыслях или кризисных состояниях немедленно обратитесь к квалифицированному специалисту."
                        )
                        
                        DisclaimerCard(
                            icon: "lock.shield",
                            title: "Конфиденциальность",
                            description: "Ваши данные защищены, но помните: это AI-система, а не человек-психолог со строгой врачебной тайной."
                        )
                        
                        DisclaimerCard(
                            icon: "clock",
                            title: "Дополнительная поддержка",
                            description: "Используйте приложение как дополнение к, а не замену традиционной психологической помощи."
                        )
                    }
                    
                    // Экстренные контакты
                    VStack(spacing: 12) {
                        Text("🆘 Экстренная помощь")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text("Россия: 8-800-2000-122 (Детский телефон доверия)")
                            .font(.caption)
                        Text("Экстренная психологическая помощь: 051")
                            .font(.caption)
                        Text("При угрозе жизни: 112")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Соглашение
                    VStack(spacing: 16) {
                        Text("Продолжая использование приложения, вы подтверждаете, что:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ChecklistItem(text: "Понимаете ограничения AI-консультанта")
                            ChecklistItem(text: "Будете обращаться к специалистам при необходимости")
                            ChecklistItem(text: "Используете приложение ответственно")
                            ChecklistItem(text: "Вам исполнилось 13 лет")
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Кнопки
                    VStack(spacing: 12) {
                        Button(action: acceptDisclaimer) {
                            Text("Я понимаю и согласен")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "889E8C"))
                                .cornerRadius(12)
                        }
                        
                        Button(action: cancelDisclaimer) {
                            Text("Отмена")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func acceptDisclaimer() {
        print("📱 DisclaimerView: Пользователь принял дисклеймер")
        hasAcceptedDisclaimer = true
        onAccepted()
    }
    
    private func cancelDisclaimer() {
        isPresented = false
    }
}

struct DisclaimerCard: View {
    let icon: String
    let title: String
    let description: String
    var isWarning: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isWarning ? .red : Color(hex: "889E8C"))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isWarning ? Color.red.opacity(0.05) : Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isWarning ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

struct ChecklistItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "889E8C"))
                .font(.body)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}
