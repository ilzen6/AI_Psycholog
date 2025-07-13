//
//  MoodJournalView.swift - ИСПРАВЛЕННАЯ версия без ошибок
//  AI_Psycholog
//
//  Исправлены все синтаксические ошибки и структура кода
//

import SwiftUI

struct MoodJournalView: View {
    @State private var moodEntries: [ManualMoodEntry] = []
    @State private var selectedPeriod: TimeFilter = .week
    @State private var showingAddMood = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Статистика настроения
                moodStatsSection
                
                // Основной контент
                if isLoading {
                    loadingSection
                } else if let error = errorMessage {
                    errorSection(error)
                } else {
                    moodEntriesSection
                }
            }
            .navigationTitle("Журнал настроения")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddMood = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "889E8C"),
                                                Color(hex: "6B7F6F")
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: Color(hex: "889E8C").opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .sheet(isPresented: $showingAddMood) {
                AddMoodView { mood, note in
                    addMoodEntry(mood: mood, note: note)
                }
            }
            .onAppear {
                loadMoodEntries()
            }
        }
    }
    
    private var moodStatsSection: some View {
        VStack(spacing: 16) {
            // Переключатель периода
            Picker("Период", selection: $selectedPeriod) {
                ForEach(TimeFilter.allCases, id: \.self) { period in
                    Text(period.title).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Статистика
            HStack(spacing: 20) {
                MoodStatCard(
                    title: "Записей",
                    value: "\(filteredMoodEntries.count)",
                    icon: "doc.text",
                    color: .blue
                )
                
                MoodStatCard(
                    title: "Хороших дней",
                    value: "\(getGoodDaysCount())",
                    icon: "sun.max.fill",
                    color: .orange
                )
                
                MoodStatCard(
                    title: "Дней подряд",
                    value: "\(getStreakDays())",
                    icon: "flame.fill",
                    color: .green
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var loadingSection: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "889E8C")))
                .scaleEffect(1.5)
            
            Text("Загружаем записи...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorSection(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Ошибка загрузки")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Повторить") {
                loadMoodEntries()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(hex: "889E8C"))
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var moodEntriesSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredMoodEntries) { entry in
                    FixedPremiumMoodEntryCard(entry: entry) {
                        deleteMoodEntry(entry)
                    }
                }
                
                if filteredMoodEntries.isEmpty {
                    EmptyMoodStateView(onAddMood: {
                        showingAddMood = true
                    })
                }
            }
            .padding()
        }
    }
    
    private var filteredMoodEntries: [ManualMoodEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        let filtered = moodEntries.filter { entry in
            switch selectedPeriod {
            case .week:
                return calendar.isDate(entry.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(entry.date, equalTo: now, toGranularity: .month)
            case .year:
                return calendar.isDate(entry.date, equalTo: now, toGranularity: .year)
            case .all:
                return true
            }
        }.sorted { $0.date > $1.date }
        
        return filtered
    }
    
    private func getGoodDaysCount() -> Int {
        return filteredMoodEntries.filter { $0.rating >= 4 }.count
    }
    
    private func getStreakDays() -> Int {
        guard !moodEntries.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedEntries = moodEntries.sorted { $0.date > $1.date }
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // Группируем записи по дням
        let entriesByDay = Dictionary(grouping: sortedEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        
        // Проверяем последовательность дней
        while let _ = entriesByDay[currentDate] {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    private func addMoodEntry(mood: MoodLevel, note: String) {
        let rating = mood.score // 1-5
        
        let newEntry = ManualMoodEntry(
            rating: rating,
            note: note,
            date: Date()
        )
        
        moodEntries.insert(newEntry, at: 0)
        saveMoodEntries()
        
        print("✅ Добавлена запись с рейтингом: \(rating) (\(mood.rawValue))")
        
        // Также отправляем на сервер
        APIManager.shared.addMoodRecord(moodLevel: mood, note: note) { result in
            switch result {
            case .success:
                print("✅ Запись настроения сохранена на сервере")
            case .failure(let error):
                print("❌ Ошибка сохранения на сервере: \(error)")
            }
        }
    }
    
    private func deleteMoodEntry(_ entry: ManualMoodEntry) {
        moodEntries.removeAll { $0.id == entry.id }
        saveMoodEntries()
    }
    
    private func loadMoodEntries() {
        isLoading = true
        errorMessage = nil
        
        // Загружаем из UserDefaults
        if let data = UserDefaults.standard.data(forKey: "manualMoodEntries"),
           let entries = try? JSONDecoder().decode([ManualMoodEntry].self, from: data) {
            moodEntries = entries.sorted { $0.date > $1.date }
        }
        
        isLoading = false
    }
    
    private func saveMoodEntries() {
        if let data = try? JSONEncoder().encode(moodEntries) {
            UserDefaults.standard.set(data, forKey: "manualMoodEntries")
        }
    }
}

// MARK: - MoodSelectionButton для AddMoodView
struct MoodSelectionButton: View {
    let rating: Int
    @Binding var selectedRating: Int
    
    var body: some View {
        let moodLevel = MoodLevel.from(score: rating)
        let isSelected = selectedRating == rating
        
        Button(action: {
            selectedRating = rating
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? moodLevel.color.opacity(0.15) : Color.clear)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(moodLevel.color, lineWidth: isSelected ? 3 : 2)
                        )
                    
                    moodLevel.image
                        .scaleEffect(isSelected ? 1.3 : 1.1)
                }
                
                Text(moodLevel.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? moodLevel.color : .secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 80, height: 120)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Premium Mood Entry Card с кастомными иконками
struct FixedPremiumMoodEntryCard: View {
    let entry: ManualMoodEntry
    let onDelete: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Верхняя часть с градиентом
            ZStack {
                // Градиентный фон
                LinearGradient(
                    gradient: Gradient(colors: [
                        entry.moodLevel.color,
                        entry.moodLevel.color.opacity(0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 80)
                
                // Декоративные элементы
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .offset(x: 20, y: -20)
                    
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 40, height: 40)
                        .offset(x: 10, y: 10)
                }
                
                // Основной контент верхней части
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 54, height: 54)
                        
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 48, height: 48)
                        
                        entry.moodLevel.image
                            .scaleEffect(1.3)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.moodLevel.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 6) {
                            ForEach(1...5, id: \.self) { index in
                                Circle()
                                    .fill(index <= entry.rating ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 20)
                    .path(in: CGRect(x: 0, y: 0, width: 1000, height: 80))
            )
            
            // Нижняя часть с информацией
            VStack(alignment: .leading, spacing: 12) {
                // Только дата без времени
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text(entry.date, style: .date)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Заметка
                if !entry.note.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "note.text")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            Text("Заметка")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Text(entry.note)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.primary)
                            .lineLimit(nil)
                            .padding(.leading, 22)
                    }
                }
                
                // Кнопка удаления
                HStack {
                    Spacer()
                    
                    Button(action: onDelete) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                            
                            Text("Удалить")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(20)
            .background(Color(UIColor.secondarySystemBackground))
        }
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        .shadow(color: entry.moodLevel.color.opacity(0.2), radius: 15, x: 0, y: 8)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Manual Mood Entry Model
struct ManualMoodEntry: Identifiable, Codable {
    let id = UUID()
    let rating: Int // 1-5
    let note: String
    let date: Date
    
    var moodLevel: MoodLevel {
        return MoodLevel.from(score: rating)
    }
    
    enum CodingKeys: String, CodingKey {
        case rating, note, date
    }
    
    init(rating: Int, note: String, date: Date) {
        self.rating = rating
        self.note = note
        self.date = date
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rating = try container.decode(Int.self, forKey: .rating)
        note = try container.decode(String.self, forKey: .note)
        date = try container.decode(Date.self, forKey: .date)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rating, forKey: .rating)
        try container.encode(note, forKey: .note)
        try container.encode(date, forKey: .date)
    }
}

// MARK: - Add Mood View
struct AddMoodView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedRating: Int = 3
    @State private var note: String = ""
    let onSave: (MoodLevel, String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Text("Как ваше настроение?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    // Красивые выровненные иконки в сетке 3x2
                    VStack(spacing: 20) {
                        // Первый ряд: 1, 2, 3
                        HStack(spacing: 20) {
                            ForEach(1...3, id: \.self) { rating in
                                MoodSelectionButton(
                                    rating: rating,
                                    selectedRating: $selectedRating
                                )
                            }
                        }
                        
                        // Второй ряд: 4, 5 (по центру)
                        HStack(spacing: 20) {
                            Spacer()
                            ForEach(4...5, id: \.self) { rating in
                                MoodSelectionButton(
                                    rating: rating,
                                    selectedRating: $selectedRating
                                )
                            }
                            Spacer()
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Запись настроения")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextEditor(text: $note)
                        .frame(height: 120)
                        .padding(12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Spacer()
                
                Button(action: save) {
                    Text("Сохранить")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "889E8C"))
                        .cornerRadius(12)
                }
                .padding(.bottom, 20)
            }
            .padding()
            .navigationTitle("Добавить запись")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func save() {
        let moodLevel: MoodLevel
        switch selectedRating {
        case 1: moodLevel = .verySad
        case 2: moodLevel = .sad
        case 3: moodLevel = .neutral
        case 4: moodLevel = .happy
        case 5: moodLevel = .veryHappy
        default: moodLevel = .neutral
        }
        
        onSave(moodLevel, note)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Supporting Views
struct EmptyMoodStateView: View {
    let onAddMood: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Красивая иконка
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "889E8C").opacity(0.2),
                                Color(hex: "889E8C").opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "face.smiling")
                    .font(.system(size: 50))
                    .foregroundColor(Color(hex: "889E8C"))
            }
            
            VStack(spacing: 12) {
                Text("Нет записей за выбранный период")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Начните вести журнал настроения\nчтобы отслеживать свое эмоциональное состояние")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            Button(action: onAddMood) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Добавить запись")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "889E8C"),
                            Color(hex: "6B7F6F")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: Color(hex: "889E8C").opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct MoodStatCard: View {
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
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
    }
}
