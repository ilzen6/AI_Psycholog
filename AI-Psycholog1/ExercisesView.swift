//
//  ExercisesView.swift - исправленная версия с поддержкой темной темы
//  AI_Psycholog
//
//  Исправлена поддержка темной темы для всех элементов
//

import SwiftUI

// MARK: - Models

enum ExerciseCategory: CaseIterable {
    case breathing
    case meditation
    case muscle
    case visualization
    
    var title: String {
        switch self {
        case .breathing: return "Дыхание"
        case .meditation: return "Медитация"
        case .muscle: return "Мышечная релаксация"
        case .visualization: return "Визуализация"
        }
    }
    
    var icon: String {
        switch self {
        case .breathing: return "wind.circle.fill"
        case .meditation: return "leaf.circle.fill"
        case .muscle: return "figure.strengthtraining.traditional"
        case .visualization: return "eye.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .breathing:
            return Color(hex: "4A90E2")
        case .meditation:
            return Color(hex: "7ED321")
        case .muscle:
            return Color(hex: "F5A623")
        case .visualization:
            return Color(hex: "9013FE")
        }
    }
}

struct ExerciseStep {
    let instruction: String
    let duration: Int // в секундах, 0 = без таймера
}

struct RelaxationExercise: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: ExerciseCategory
    let duration: Int // в минутах
    let difficulty: Int // 1-5 звезд
    let steps: [ExerciseStep]
}

struct ExercisesView: View {
    @State private var selectedCategory: ExerciseCategory = .breathing
    @State private var showingExercise: RelaxationExercise?
    @State private var searchText = ""
    @State private var isSearching = false
    @Environment(\.colorScheme) var colorScheme
    
    let exerciseCategories = ExerciseCategory.allCases
    
    var body: some View {
        NavigationView {
            ZStack {
                // Адаптивный фон для темной темы
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Заголовок с поиском
                    headerSection
                    
                    // Категории с анимацией
                    categorySection
                    
                    // Основной контент
                    mainContentSection
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(item: $showingExercise) { exercise in
            ExerciseDetailView(exercise: exercise) {
                showingExercise = nil
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Упражнения")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Путь к внутреннему спокойствию")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Кнопка поиска
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isSearching.toggle()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                            .frame(width: 44, height: 44)
                            .shadow(color: colorScheme == .dark ? Color.clear : .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                            .font(.title3)
                            .foregroundColor(Color(hex: "889E8C"))
                    }
                }
            }
            
            // Поисковая строка
            if isSearching {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Поиск упражнений...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .shadow(color: colorScheme == .dark ? Color.clear : .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 20)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(exerciseCategories, id: \.self) { category in
                    PremiumCategoryChip(
                        category: category,
                        isSelected: selectedCategory == category,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var mainContentSection: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(filteredExercises) { exercise in
                    PremiumExerciseCard(
                        exercise: exercise,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showingExercise = exercise
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private var filteredExercises: [RelaxationExercise] {
        let categoryExercises = RelaxationExercise.allExercises.filter { $0.category == selectedCategory }
        
        if searchText.isEmpty {
            return categoryExercises
        } else {
            return categoryExercises.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct PremiumCategoryChip: View {
    let category: ExerciseCategory
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                gradient: Gradient(colors: [category.color, category.color.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(UIColor.secondarySystemGroupedBackground),
                                    Color(UIColor.secondarySystemGroupedBackground)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .shadow(
                            color: isSelected ? category.color.opacity(0.3) :
                                   (colorScheme == .dark ? Color.clear : .black.opacity(0.1)),
                            radius: isSelected ? 8 : 4,
                            x: 0,
                            y: 2
                        )
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : category.color)
                }
                
                Text(category.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            gradient: Gradient(colors: [category.color, category.color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(UIColor.secondarySystemGroupedBackground),
                                Color(UIColor.secondarySystemGroupedBackground)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isSelected ? category.color.opacity(0.3) :
                               (colorScheme == .dark ? Color.clear : .black.opacity(0.08)),
                        radius: isSelected ? 12 : 8,
                        x: 0,
                        y: isSelected ? 6 : 3
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PremiumExerciseCard: View {
    let exercise: RelaxationExercise
    let colorScheme: ColorScheme
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Основная карточка с адаптивным фоном
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(
                        color: colorScheme == .dark ? Color.clear : .black.opacity(0.08),
                        radius: isPressed ? 8 : 16,
                        x: 0,
                        y: isPressed ? 4 : 8
                    )
                
                // Градиентная полоска сбоку
                HStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [exercise.category.color, exercise.category.color.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 6)
                    
                    Spacer()
                }
                .padding(.leading, 4)
                
                VStack(spacing: 20) {
                    // Верхняя секция с иконкой и основной информацией
                    HStack(alignment: .top, spacing: 16) {
                        // Красивая иконка
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            exercise.category.color.opacity(0.15),
                                            exercise.category.color.opacity(0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: exercise.category.icon)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [exercise.category.color, exercise.category.color.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(exercise.title)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Text(exercise.description)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    
                    // Нижняя секция с метаданными
                    HStack {
                        // Время
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundColor(exercise.category.color)
                            
                            Text("\(exercise.duration) мин")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(exercise.category.color.opacity(0.1))
                        )
                        
                        Spacer()
                        
                        // Звезды сложности
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < exercise.difficulty ? "star.fill" : "star")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(
                                        index < exercise.difficulty ?
                                        Color.orange :
                                        Color.orange.opacity(0.3)
                                    )
                            }
                        }
                        
                        // Стрелка
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [exercise.category.color, exercise.category.color.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .padding(24)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// ExerciseDetailView с поддержкой темной темы
struct ExerciseDetailView: View {
    let exercise: RelaxationExercise
    let onDismiss: () -> Void
    
    @State private var isRunning = false
    @State private var currentStep = 0
    @State private var timer: Timer?
    @State private var timeRemaining = 0
    @State private var totalTime = 0
    @State private var showingCompleted = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Адаптивный фон
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Кастомная навигационная панель
                customNavigationBar
                
                if !isRunning {
                    preparationScreen
                } else {
                    exerciseScreen
                }
            }
        }
        .onDisappear {
            stopExercise()
        }
        .alert("Упражнение завершено! 🎉", isPresented: $showingCompleted) {
            Button("Отлично!") {
                onDismiss()
            }
        } message: {
            Text("Вы успешно выполнили упражнение \"\(exercise.title)\". Продолжайте практиковать для достижения лучших результатов!")
        }
    }
    
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                stopExercise()
                onDismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .frame(width: 44, height: 44)
                        .shadow(color: colorScheme == .dark ? Color.clear : .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "xmark")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            if isRunning {
                VStack(spacing: 4) {
                    Text("Шаг \(currentStep + 1) из \(exercise.steps.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: Double(currentStep), total: Double(exercise.steps.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: exercise.category.color))
                        .frame(width: 120)
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                ZStack {
                    Circle()
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .frame(width: 44, height: 44)
                        .shadow(color: colorScheme == .dark ? Color.clear : .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "heart")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 20)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var preparationScreen: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Большая иконка
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    exercise.category.color.opacity(0.2),
                                    exercise.category.color.opacity(0.05)
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 160, height: 160)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [exercise.category.color.opacity(0.3), exercise.category.color.opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                    
                    Image(systemName: exercise.category.icon)
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [exercise.category.color, exercise.category.color.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.top, 20)
                
                // Информация об упражнении
                VStack(spacing: 16) {
                    Text(exercise.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(exercise.description)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .padding(.horizontal, 20)
                }
                
                // Метаданные в карточках
                HStack(spacing: 16) {
                    MetadataCard(
                        title: "Время",
                        value: "\(exercise.duration) мин",
                        icon: "clock.fill",
                        color: exercise.category.color,
                        colorScheme: colorScheme
                    )
                    
                    MetadataCard(
                        title: "Сложность",
                        value: "\(exercise.difficulty)/5",
                        icon: "star.fill",
                        color: .orange,
                        colorScheme: colorScheme
                    )
                    
                    MetadataCard(
                        title: "Шагов",
                        value: "\(exercise.steps.count)",
                        icon: "list.bullet",
                        color: .blue,
                        colorScheme: colorScheme
                    )
                }
                .padding(.horizontal, 20)
                
                // Предварительный просмотр шагов
                VStack(alignment: .leading, spacing: 16) {
                    Text("Что вас ждет:")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                    
                    ForEach(Array(exercise.steps.prefix(3).enumerated()), id: \.offset) { index, step in
                        StepPreviewCard(
                            stepNumber: index + 1,
                            step: step,
                            color: exercise.category.color,
                            colorScheme: colorScheme
                        )
                    }
                    
                    if exercise.steps.count > 3 {
                        HStack {
                            Spacer()
                            Text("и еще \(exercise.steps.count - 3) шаг(ов)...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(.bottom, 120)
        }
        .overlay(
            VStack {
                Spacer()
                
                Button(action: startExercise) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.title3)
                        Text("Начать упражнение")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [exercise.category.color, exercise.category.color.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: exercise.category.color.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        )
    }
    
    private var exerciseScreen: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Таймер или иконка
            if timeRemaining > 0 {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [exercise.category.color.opacity(0.2), exercise.category.color.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 8
                        )
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .trim(from: 0, to: 1.0 - (Double(timeRemaining) / Double(exercise.steps[currentStep].duration)))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [exercise.category.color, exercise.category.color.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timeRemaining)
                    
                    VStack(spacing: 4) {
                        Text("\(timeRemaining)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("секунд")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    exercise.category.color.opacity(0.2),
                                    exercise.category.color.opacity(0.05)
                                ]),
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    Image(systemName: exercise.category.icon)
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [exercise.category.color, exercise.category.color.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            
            // Текущий шаг
            if currentStep < exercise.steps.count {
                VStack(spacing: 16) {
                    Text(exercise.steps[currentStep].instruction)
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .padding(.horizontal, 30)
                        .animation(.easeInOut(duration: 0.5), value: currentStep)
                }
            }
            
            Spacer()
            
            // Кнопки управления
            HStack(spacing: 20) {
                Button(action: stopExercise) {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                        Text("Остановить")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                Button(action: nextStep) {
                    HStack(spacing: 8) {
                        Text(currentStep < exercise.steps.count - 1 ? "Далее" : "Завершить")
                            .fontWeight(.semibold)
                        Image(systemName: currentStep < exercise.steps.count - 1 ? "arrow.right" : "checkmark")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [exercise.category.color, exercise.category.color.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: exercise.category.color.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Exercise Logic
    
    private func startExercise() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isRunning = true
            currentStep = 0
        }
        startStepTimer()
    }
    
    private func stopExercise() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isRunning = false
        }
        timer?.invalidate()
        timer = nil
        currentStep = 0
        timeRemaining = 0
    }
    
    private func nextStep() {
        timer?.invalidate()
        
        if currentStep < exercise.steps.count - 1 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentStep += 1
            }
            startStepTimer()
        } else {
            completeExercise()
        }
    }
    
    private func startStepTimer() {
        let step = exercise.steps[currentStep]
        if step.duration > 0 {
            timeRemaining = step.duration
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                timeRemaining -= 1
                if timeRemaining <= 0 {
                    nextStep()
                }
            }
        } else {
            timeRemaining = 0
        }
    }
    
    private func completeExercise() {
        stopExercise()
        showingCompleted = true
    }
}

// MARK: - Supporting Views

struct MetadataCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: colorScheme == .dark ? Color.clear : .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct StepPreviewCard: View {
    let stepNumber: Int
    let step: ExerciseStep
    let color: Color
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Text("\(stepNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(step.instruction)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if step.duration > 0 {
                    Text("\(step.duration) секунд")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.tertiarySystemGroupedBackground))
                .shadow(color: colorScheme == .dark ? Color.clear : .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Exercise Data

extension RelaxationExercise {
    static let allExercises: [RelaxationExercise] = [
        // Дыхательные упражнения
        RelaxationExercise(
            title: "Дыхание 4-7-8",
            description: "Мощная техника для быстрого расслабления и улучшения сна. Основана на древних практиках йоги.",
            category: .breathing,
            duration: 5,
            difficulty: 3,
            steps: [
                ExerciseStep(instruction: "Устройтесь удобно в тихом месте, выпрямите спину", duration: 15),
                ExerciseStep(instruction: "Полностью выдохните через рот, издавая свистящий звук", duration: 10),
                ExerciseStep(instruction: "Закройте рот и медленно вдыхайте через нос на 4 счета", duration: 4),
                ExerciseStep(instruction: "Задержите дыхание на 7 счетов", duration: 7),
                ExerciseStep(instruction: "Выдыхайте через рот на 8 счетов со звуком", duration: 8),
                ExerciseStep(instruction: "Повторите цикл еще 3 раза, концентрируясь на счете", duration: 60)
            ]
        ),
        
        RelaxationExercise(
            title: "Квадратное дыхание",
            description: "Простая, но эффективная техника для восстановления баланса нервной системы",
            category: .breathing,
            duration: 8,
            difficulty: 2,
            steps: [
                ExerciseStep(instruction: "Сядьте прямо, положите руки на колени", duration: 10),
                ExerciseStep(instruction: "Медленно вдыхайте через нос на 4 счета", duration: 4),
                ExerciseStep(instruction: "Задержите дыхание на 4 счета", duration: 4),
                ExerciseStep(instruction: "Медленно выдыхайте через рот на 4 счета", duration: 4),
                ExerciseStep(instruction: "Задержитесь без дыхания на 4 счета", duration: 4),
                ExerciseStep(instruction: "Продолжайте цикл в течение 5 минут", duration: 300)
            ]
        ),
        
        RelaxationExercise(
            title: "Энергизирующее дыхание",
            description: "Динамичная техника для повышения энергии и концентрации внимания",
            category: .breathing,
            duration: 6,
            difficulty: 4,
            steps: [
                ExerciseStep(instruction: "Встаньте прямо, руки вдоль тела", duration: 10),
                ExerciseStep(instruction: "Сделайте 20 быстрых глубоких вдохов-выдохов", duration: 30),
                ExerciseStep(instruction: "Глубокий вдох, задержите дыхание", duration: 15),
                ExerciseStep(instruction: "Медленный выдох с расслаблением", duration: 10),
                ExerciseStep(instruction: "Повторите весь цикл 3 раза", duration: 180)
            ]
        ),
        
        // Медитация
        RelaxationExercise(
            title: "Сканирование тела",
            description: "Глубокая практика осознанности для полного расслабления и восстановления",
            category: .meditation,
            duration: 15,
            difficulty: 3,
            steps: [
                ExerciseStep(instruction: "Лягте на спину, руки вдоль тела, глаза закрыты", duration: 30),
                ExerciseStep(instruction: "Сосредоточьтесь на дыхании, почувствуйте его ритм", duration: 60),
                ExerciseStep(instruction: "Переместите внимание на пальцы ног, расслабьте их", duration: 45),
                ExerciseStep(instruction: "Медленно поднимайтесь вверх: стопы, голени, колени", duration: 90),
                ExerciseStep(instruction: "Расслабьте бедра, ягодицы, поясницу", duration: 60),
                ExerciseStep(instruction: "Почувствуйте живот, грудь, плечи", duration: 90),
                ExerciseStep(instruction: "Расслабьте руки: от плеч до кончиков пальцев", duration: 60),
                ExerciseStep(instruction: "Сосредоточьтесь на шее, лице, макушке", duration: 60),
                ExerciseStep(instruction: "Ощутите все тело как единое целое", duration: 120),
                ExerciseStep(instruction: "Медленно возвращайтесь к обычному состоянию", duration: 45)
            ]
        ),
        
        RelaxationExercise(
            title: "Любящая доброта",
            description: "Медитация сострадания для развития позитивных эмоций и улучшения отношений",
            category: .meditation,
            duration: 12,
            difficulty: 2,
            steps: [
                ExerciseStep(instruction: "Сядьте удобно, закройте глаза, успокойте дыхание", duration: 30),
                ExerciseStep(instruction: "Представьте себя и мысленно скажите: 'Пусть я буду счастлив'", duration: 90),
                ExerciseStep(instruction: "Продолжите: 'Пусть я буду здоров и в безопасности'", duration: 90),
                ExerciseStep(instruction: "Представьте близкого человека, пошлите ему те же пожелания", duration: 120),
                ExerciseStep(instruction: "Представьте нейтрального человека, пошлите добрые мысли", duration: 90),
                ExerciseStep(instruction: "Представьте сложного для вас человека, пожелайте ему добра", duration: 120),
                ExerciseStep(instruction: "Расширьте пожелания на всех живых существ", duration: 90),
                ExerciseStep(instruction: "Завершите, почувствовав тепло в сердце", duration: 30)
            ]
        ),
        
        // Мышечная релаксация
        RelaxationExercise(
            title: "Прогрессивная релаксация",
            description: "Классическая техника Джекобсона для глубокого физического и ментального расслабления",
            category: .muscle,
            duration: 20,
            difficulty: 4,
            steps: [
                ExerciseStep(instruction: "Лягте в удобное положение, руки вдоль тела", duration: 30),
                ExerciseStep(instruction: "Напрягите мышцы лица на 7 секунд, затем расслабьте", duration: 20),
                ExerciseStep(instruction: "Напрягите шею и плечи, удерживайте, расслабьте", duration: 20),
                ExerciseStep(instruction: "Сожмите кулаки, напрягите руки, затем отпустите", duration: 20),
                ExerciseStep(instruction: "Напрягите мышцы груди и спины, расслабьте", duration: 20),
                ExerciseStep(instruction: "Втяните живот, напрягите, затем расслабьте", duration: 20),
                ExerciseStep(instruction: "Напрягите ягодицы и бедра, удерживайте, отпустите", duration: 20),
                ExerciseStep(instruction: "Напрягите голени и стопы, затем расслабьте", duration: 20),
                ExerciseStep(instruction: "Напрягите все тело одновременно на 10 секунд", duration: 15),
                ExerciseStep(instruction: "Полностью расслабьтесь, почувствуйте покой", duration: 180)
            ]
        ),
        
        RelaxationExercise(
            title: "Быстрая релаксация",
            description: "Эффективная техника для снятия напряжения за короткое время",
            category: .muscle,
            duration: 7,
            difficulty: 2,
            steps: [
                ExerciseStep(instruction: "Сядьте удобно, положите руки на бедра", duration: 10),
                ExerciseStep(instruction: "Поднимите плечи к ушам, задержите на 5 секунд", duration: 8),
                ExerciseStep(instruction: "Резко опустите плечи, почувствуйте расслабление", duration: 5),
                ExerciseStep(instruction: "Сожмите кулаки, напрягите руки на 5 секунд", duration: 8),
                ExerciseStep(instruction: "Разожмите кулаки, встряхните руками", duration: 5),
                ExerciseStep(instruction: "Повторите с мышцами ног: напряжение-расслабление", duration: 15),
                ExerciseStep(instruction: "Сделайте 3 глубоких вдоха, полностью расслабьтесь", duration: 20)
            ]
        ),
        
        // Визуализация
        RelaxationExercise(
            title: "Безопасное место",
            description: "Создание внутреннего убежища для восстановления эмоционального равновесия",
            category: .visualization,
            duration: 10,
            difficulty: 3,
            steps: [
                ExerciseStep(instruction: "Закройте глаза, сделайте несколько глубоких вдохов", duration: 30),
                ExerciseStep(instruction: "Представьте место, где вы чувствуете себя в полной безопасности", duration: 60),
                ExerciseStep(instruction: "Рассмотрите детали: что вы видите вокруг себя?", duration: 90),
                ExerciseStep(instruction: "Какие звуки вы слышите в этом месте?", duration: 60),
                ExerciseStep(instruction: "Какие запахи и ощущения чувствуете?", duration: 60),
                ExerciseStep(instruction: "Почувствуйте температуру, текстуры вокруг вас", duration: 60),
                ExerciseStep(instruction: "Ощутите глубокий покой и защищенность", duration: 90),
                ExerciseStep(instruction: "Запомните это чувство, вы можете вернуться сюда в любой момент", duration: 60),
                ExerciseStep(instruction: "Медленно откройте глаза, сохраняя ощущение покоя", duration: 30)
            ]
        ),
        
        RelaxationExercise(
            title: "Исцеляющий свет",
            description: "Мощная визуализация для восстановления энергии и внутреннего исцеления",
            category: .visualization,
            duration: 12,
            difficulty: 4,
            steps: [
                ExerciseStep(instruction: "Лягте удобно, расслабьтесь, закройте глаза", duration: 30),
                ExerciseStep(instruction: "Представьте теплый золотистый свет над вашей головой", duration: 60),
                ExerciseStep(instruction: "Этот свет медленно входит в вашу макушку", duration: 45),
                ExerciseStep(instruction: "Свет заполняет вашу голову, принося ясность и покой", duration: 60),
                ExerciseStep(instruction: "Свет спускается в шею, плечи, руки", duration: 60),
                ExerciseStep(instruction: "Исцеляющий свет заполняет грудь и сердце", duration: 90),
                ExerciseStep(instruction: "Свет течет в живот, поясницу, таз", duration: 60),
                ExerciseStep(instruction: "Исцеляющая энергия заполняет ноги до кончиков пальцев", duration: 60),
                ExerciseStep(instruction: "Все ваше тело светится исцеляющим светом", duration: 90),
                ExerciseStep(instruction: "Почувствуйте обновление и восстановление", duration: 60),
                ExerciseStep(instruction: "Медленно возвращайтесь, сохраняя энергию света", duration: 30)
            ]
        ),
        
        RelaxationExercise(
            title: "Лесная прогулка",
            description: "Успокаивающая визуализация для снятия стресса и восстановления сил",
            category: .visualization,
            duration: 8,
            difficulty: 2,
            steps: [
                ExerciseStep(instruction: "Устройтесь удобно, закройте глаза", duration: 20),
                ExerciseStep(instruction: "Представьте себя на краю красивого леса", duration: 45),
                ExerciseStep(instruction: "Идите по мягкой лесной тропинке", duration: 60),
                ExerciseStep(instruction: "Слушайте пение птиц и шелест листьев", duration: 60),
                ExerciseStep(instruction: "Почувствуйте свежий лесной воздух", duration: 45),
                ExerciseStep(instruction: "Найдите уютную поляну и отдохните", duration: 90),
                ExerciseStep(instruction: "Ощутите связь с природой и умиротворение", duration: 90),
                ExerciseStep(instruction: "Медленно вернитесь из леса, открыв глаза", duration: 30)
            ]
        )
    ]
}
