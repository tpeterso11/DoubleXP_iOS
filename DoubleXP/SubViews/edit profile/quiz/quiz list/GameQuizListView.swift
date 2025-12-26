//
//  GameQuizListView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/17/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

struct GameQuizListView: View {
    @StateObject private var viewModel: GameQuizListViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation: QuizListItem?
    @State private var selectedQuizForEdit: QuizListItem?
    @State private var selectedQuizToTake: GameQuiz?
    
    init(userId: String) {
        _viewModel = StateObject(wrappedValue: GameQuizListViewModel(userId: userId))
    }
    
    var body: some View {
        mainContent
            .confirmationDialog(
                "Delete Quiz",
                isPresented: deleteConfirmationBinding,
                presenting: showDeleteConfirmation
            ) { item in
                deleteDialogButtons(for: item)
            } message: { item in
                deleteDialogMessage(for: item)
            }
            .sheet(item: $selectedQuizForEdit) { item in
                QuizEditView(quizItem: item)
            }
            .fullScreenCover(item: $selectedQuizToTake) { quiz in
                quizTakingView(for: quiz)
            }
            .onChange(of: selectedQuizToTake) { _, quiz in
                handleQuizTakingDismiss(quiz)
            }
            .onChange(of: selectedQuizForEdit) { _, item in
                handleQuizEditDismiss(item)
            }
            .task {
                await viewModel.loadQuizzes()
            }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack {
            backgroundView
            
            VStack(spacing: 0) {
                headerView
                contentView
            }
            
            introOverlay
        }
    }

    // MARK: - Intro Overlay

    @ViewBuilder
    private var introOverlay: some View {
        if viewModel.showIntroOverlay {
            IntroOverlayView(onDismiss: {
                viewModel.markIntroAsSeen()
            })
        }
    }

    // MARK: - Dialog Bindings & Content

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { showDeleteConfirmation != nil },
            set: { if !$0 { showDeleteConfirmation = nil } }
        )
    }

    @ViewBuilder
    private func deleteDialogButtons(for item: QuizListItem) -> some View {
        Button("Delete", role: .destructive) {
            Task {
                await viewModel.deleteCompletion(item)
            }
        }
        Button("Cancel", role: .cancel) {}
    }

    private func deleteDialogMessage(for item: QuizListItem) -> some View {
        Text("Are you sure you want to delete your \(item.quiz.title) quiz? This cannot be undone.")
    }

    // MARK: - Full Screen Cover Content

    private func quizTakingView(for quiz: GameQuiz) -> some View {
        GameQuizTakingView(
            quiz: quiz,
            userId: UserProvider.shared.getUser()?.uId ?? ""
        )
    }

    // MARK: - Change Handlers

    private func handleQuizTakingDismiss(_ quiz: GameQuiz?) {
        if quiz == nil {
            Task {
                await viewModel.refreshQuizzes()
            }
        }
    }

    private func handleQuizEditDismiss(_ item: QuizListItem?) {
        if item == nil {
            Task {
                await viewModel.refreshQuizzes()
            }
        }
    }

    // MARK: - Add these computed properties after the body:

    private var backgroundView: some View {
        Color(red: 0.06, green: 0.06, blue: 0.06)
            .ignoresSafeArea()
    }

    private var contentView: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(error)
            } else {
                mainScrollView
            }
        }
    }

    private var mainScrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                valuePropBox
                completedQuizzesSection
                availableQuizzesSection
                Color.clear.frame(height: 40)
            }
        }
    }

    private var completedQuizzesSection: some View {
        Group {
            if !viewModel.completedQuizzes.isEmpty {
                sectionHeader(title: "COMPLETED", count: viewModel.completedQuizzes.count)
                
                ForEach(viewModel.completedQuizzes) { item in
                    QuizNeuroCard(
                        item: item,
                        onEdit: {
                            selectedQuizForEdit = item
                        },
                        onDelete: {
                            showDeleteConfirmation = item
                        }
                    )
                }
            }
        }
    }

    private var availableQuizzesSection: some View {
        Group {
            if !viewModel.availableQuizzes.isEmpty {
                sectionHeader(title: "AVAILABLE", count: viewModel.availableQuizzes.count)
                
                ForEach(viewModel.availableQuizzes) { item in
                    QuizNeuroCard(
                        item: item,
                        onTake: {
                            selectedQuizToTake = item.quiz
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                // Back button
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color(red: 0.06, green: 0.06, blue: 0.06))
                                .shadow(color: .black.opacity(0.6), radius: 5, x: 3, y: 3)
                                .shadow(color: .white.opacity(0.02), radius: 5, x: -3, y: -3)
                        )
                }
                
                Spacer()
                
                // Refresh button
                Button(action: {
                    Task {
                        await viewModel.refreshQuizzes()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color(red: 0.06, green: 0.06, blue: 0.06))
                                .shadow(color: .black.opacity(0.6), radius: 5, x: 3, y: 3)
                                .shadow(color: .white.opacity(0.02), radius: 5, x: -3, y: -3)
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 20)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Playstyle Tests")
                    .font(.system(size: 30, weight: .black))
                    .foregroundColor(.white)
                
                Text("Build your gaming profile through skill assessments")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
    }
    
    // MARK: - Value Prop Box
    
    private var valuePropBox: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("▸ BENEFITS")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                    .tracking(1)
                
                Spacer()
                
                Text("\(viewModel.completionPercentage)%")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                benefitRow("Get matched with compatible players")
                benefitRow("Receive targeted team invitations")
                benefitRow("Build trust before joining squads")
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.06, green: 0.06, blue: 0.06))
                .shadow(color: .black.opacity(0.5), radius: 3, x: 3, y: 3)
                .shadow(color: .white.opacity(0.02), radius: 3, x: -3, y: -3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.02), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    private func benefitRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("▸")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            Text("(\(count))")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                ShimmerLoadingCard()
                ShimmerLoadingCard()
                ShimmerLoadingCard()
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            
            Text("⚠️")
                .font(.system(size: 48))
            
            Text(error)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                Task {
                    await viewModel.loadQuizzes()
                }
            }) {
                Text("Try Again")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.06, green: 0.06, blue: 0.06))
                            .shadow(color: .black.opacity(0.6), radius: 5, x: 3, y: 3)
                            .shadow(color: .white.opacity(0.02), radius: 5, x: -3, y: -3)
                    )
            }
            
            Spacer()
        }
    }
}

// MARK: - Quiz Neuro Card

struct QuizNeuroCard: View {
    let item: QuizListItem
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    var onTake: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.quiz.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(item.quiz.gameName + " • " + item.quiz.category.displayName)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                statusBadge
            }
            
            // Description
            Text(item.quiz.description)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            // Stats or completion info
            if item.isCompleted {
                Text("Completed on \(formattedDate)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            } else {
                HStack(spacing: 12) {
                    Label("\(item.quiz.questions.count) questions", systemImage: "list.bullet")
                    Label("\(item.quiz.estimatedMinutes) min", systemImage: "clock")
                    if item.quiz.totalTaken > 0 {
                        Label(formattedTotalTaken, systemImage: "person.2")
                    }
                }
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
            }
            
            // Actions
            actionButtons
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(red: 0.06, green: 0.06, blue: 0.06))
                .shadow(color: .black.opacity(0.6), radius: 5, x: 5, y: 5)
                .shadow(color: .white.opacity(0.02), radius: 5, x: -5, y: -5)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
    
    private var statusBadge: some View {
        Text(item.isCompleted ? "✓ DONE" : "NEW")
            .font(.system(size: 10, weight: .black))
            .foregroundColor(item.isCompleted ? Color(red: 0.13, green: 0.77, blue: 0.37) : Color(red: 0.96, green: 0.62, blue: 0.04))
            .tracking(0.5)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.06, green: 0.06, blue: 0.06))
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 2, y: 2)
                    .shadow(color: .white.opacity(0.02), radius: 2, x: -2, y: -2)
            )
    }
    
    private var actionButtons: some View {
        HStack(spacing: 10) {
            if item.isCompleted {
                NeuroButton(title: "Edit", isPrimary: false) {
                    onEdit?()
                }
                
                NeuroButton(title: "Delete", isPrimary: false) {
                    onDelete?()
                }
            } else {
                NeuroButton(title: "Start Test →", isPrimary: true) {
                    onTake?()
                }
            }
        }
    }
    
    private var formattedDate: String {
        guard let date = item.completionDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private var formattedTotalTaken: String {
        let count = item.quiz.totalTaken
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}

// MARK: - Neuro Button

struct NeuroButton: View {
    let title: String
    let isPrimary: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isPrimary ? Color(red: 0.96, green: 0.62, blue: 0.04) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0.06, green: 0.06, blue: 0.06))
                        .shadow(color: isPressed ? .clear : .black.opacity(0.5), radius: isPressed ? 0 : 3, x: isPressed ? 0 : 3, y: isPressed ? 0 : 3)
                        .shadow(color: isPressed ? .clear : .white.opacity(0.02), radius: isPressed ? 0 : 3, x: isPressed ? 0 : -3, y: isPressed ? 0 : -3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    isPressed ? Color.black.opacity(0.5) : Color.clear,
                                    lineWidth: isPressed ? 2 : 0
                                )
                        )
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Shimmer Loading Card

struct ShimmerLoadingCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ShimmerBox(width: 150, height: 20)
                Spacer()
                ShimmerBox(width: 60, height: 24)
            }
            
            ShimmerBox(width: nil, height: 14)
            ShimmerBox(width: 200, height: 14)
            
            HStack(spacing: 10) {
                ShimmerBox(width: nil, height: 40)
                ShimmerBox(width: nil, height: 40)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(red: 0.06, green: 0.06, blue: 0.06))
                .shadow(color: .black.opacity(0.6), radius: 5, x: 5, y: 5)
                .shadow(color: .white.opacity(0.02), radius: 5, x: -5, y: -5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.03),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: isAnimating ? 400 : -400)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

struct ShimmerBox: View {
    let width: CGFloat?
    let height: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.05))
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : width)
    }
}

struct IntroOverlayView: View {
    let onDismiss: () -> Void
    @State private var currentPage = 0
    
    private let pages: [(icon: String, title: String, description: String)] = [
        (
            "🎮",
            "Share Your Playstyle",
            "Complete quizzes to help teammates understand how you play and communicate"
        ),
        (
            "✏️",
            "Edit Anytime",
            "Tap Edit on completed quizzes to update your answers as your playstyle evolves"
        ),
        (
            "🗑️",
            "Manage Your Profile",
            "Delete quizzes you no longer want visible to other players"
        ),
        (
            "🤝",
            "Get Better Matches",
            "Players with complete profiles get 3x more team invites and better squad compatibility"
        )
    ]
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent dismissal by tapping background
                }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Content
                VStack(spacing: 32) {
                    // Icon
                    Text(pages[currentPage].icon)
                        .font(.system(size: 80))
                    
                    // Title
                    Text(pages[currentPage].title)
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Description
                    Text(pages[currentPage].description)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 40)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)
                
                // Action button
                if currentPage == pages.count - 1 {
                    Button(action: onDismiss) {
                        Text("Get Started")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(red: 0.96, green: 0.62, blue: 0.04))
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    }) {
                        Text("Next")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.15))
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Quiz Edit View

struct QuizEditView: View {
    let quizItem: QuizListItem
    @Environment(\.dismiss) private var dismiss
    
    @State private var answers: [String: QuizAnswer]
    @State private var isSaving = false
    
    init(quizItem: QuizListItem) {
        self.quizItem = quizItem
        
        // Initialize answers from completion
        var initialAnswers: [String: QuizAnswer] = [:]
        if let completion = quizItem.completion {
            for answer in completion.answers {
                initialAnswers[answer.questionId] = answer
            }
        }
        _answers = State(initialValue: initialAnswers)
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.06)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Questions
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ForEach(Array(quizItem.quiz.questions.enumerated()), id: \.element.id) { index, question in
                            QuestionEditCard(
                                question: question,
                                questionNumber: index + 1,
                                answer: Binding(
                                    get: { answers[question.id] },
                                    set: { answers[question.id] = $0 }
                                )
                            )
                        }
                        
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            
            // Save button (floating)
            VStack {
                Spacer()
                
                Button(action: saveAnswers) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isSaving ? "Saving..." : "Save Changes")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.96, green: 0.62, blue: 0.04))
                            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                    )
                }
                .disabled(isSaving)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Edit Quiz")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
                
                Text(quizItem.quiz.title)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
    }
    
    private func saveAnswers() {
        isSaving = true
        
        Task {
            // Create updated completion
            let updatedCompletion = UserQuizCompletion(
                id: quizItem.completion?.id ?? UUID().uuidString,
                userId: quizItem.completion?.userId ?? "",
                quizId: quizItem.quiz.id,
                answers: Array(answers.values),
                completedAt: quizItem.completion?.completedAt ?? Date().timeIntervalSince1970,
                lastModifiedAt: Date().timeIntervalSince1970,
                isPublic: quizItem.completion?.isPublic ?? true
            )
            
            do {
                try await GameQuizRequestManager.shared.saveQuizCompletion(updatedCompletion)
                
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                print("❌ Failed to save: \(error)")
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - Question Edit Card

struct QuestionEditCard: View {
    let question: QuizQuestion
    let questionNumber: Int
    @Binding var answer: QuizAnswer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question number and text
            VStack(alignment: .leading, spacing: 6) {
                Text("Question \(questionNumber)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                    .tracking(1)
                
                Text(question.questionText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Answer options
            if question.questionType == .singleChoice {
                singleChoiceOptions
            } else if question.questionType == .multipleChoice {
                multipleChoiceOptions
            } else if question.questionType == .yesNo {
                yesNoOptions
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.06, green: 0.06, blue: 0.06))
                .shadow(color: .black.opacity(0.5), radius: 3, x: 3, y: 3)
                .shadow(color: .white.opacity(0.02), radius: 3, x: -3, y: -3)
        )
    }
    
    private var singleChoiceOptions: some View {
        VStack(spacing: 10) {
            ForEach(question.options, id: \.self) { option in
                let isSelected = answer?.selectedOptions.contains(option) ?? false
                
                Button(action: {
                    answer = QuizAnswer(
                        questionId: question.id,
                        selectedOptions: [option],
                        textResponse: nil
                    )
                }) {
                    HStack {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? Color(red: 0.96, green: 0.62, blue: 0.04) : .white.opacity(0.3))
                        
                        Text(option)
                            .font(.system(size: 14))
                            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                        
                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.1) : Color.white.opacity(0.03))
                    )
                }
            }
        }
    }
    
    private var multipleChoiceOptions: some View {
        VStack(spacing: 10) {
            ForEach(question.options, id: \.self) { option in
                let isSelected = answer?.selectedOptions.contains(option) ?? false
                
                Button(action: {
                    var currentSelections = answer?.selectedOptions ?? []
                    if isSelected {
                        currentSelections.removeAll { $0 == option }
                    } else {
                        currentSelections.append(option)
                    }
                    
                    answer = QuizAnswer(
                        questionId: question.id,
                        selectedOptions: currentSelections,
                        textResponse: nil
                    )
                }) {
                    HStack {
                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? Color(red: 0.96, green: 0.62, blue: 0.04) : .white.opacity(0.3))
                        
                        Text(option)
                            .font(.system(size: 14))
                            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                        
                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.1) : Color.white.opacity(0.03))
                    )
                }
            }
        }
    }
    
    private var yesNoOptions: some View {
        HStack(spacing: 12) {
            ForEach(["Yes", "No"], id: \.self) { option in
                let isSelected = answer?.selectedOptions.contains(option) ?? false
                
                Button(action: {
                    answer = QuizAnswer(
                        questionId: question.id,
                        selectedOptions: [option],
                        textResponse: nil
                    )
                }) {
                    Text(option)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? Color(red: 0.96, green: 0.62, blue: 0.04) : Color.white.opacity(0.05))
                        )
                }
            }
        }
    }
}
