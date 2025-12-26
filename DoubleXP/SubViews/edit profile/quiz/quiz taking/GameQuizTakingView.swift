//
//  GameQuizTakingView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/17/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import SwiftUI

struct GameQuizTakingView: View {
    @StateObject private var viewModel: GameQuizTakingViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var slideDirection: SlideDirection = .forward
    @State private var showSubmitSuccess = false
    
    enum SlideDirection {
        case forward
        case backward
    }
    
    init(quiz: GameQuiz, userId: String, existingCompletion: UserQuizCompletion? = nil) {
        _viewModel = StateObject(wrappedValue: GameQuizTakingViewModel(
            quiz: quiz,
            userId: userId,
            existingCompletion: existingCompletion
        ))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.06, green: 0.06, blue: 0.06)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                if viewModel.showConfirmation {
                    confirmationView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    questionView
                        .transition(.asymmetric(
                            insertion: .move(edge: slideDirection == .forward ? .trailing : .leading)
                                .combined(with: .opacity),
                            removal: .move(edge: slideDirection == .forward ? .leading : .trailing)
                                .combined(with: .opacity)
                        ))
                }
            }
            
            // Submit success overlay
            if showSubmitSuccess {
                successOverlay
            }
        }
        .alert("Save Progress?", isPresented: $viewModel.showExitAlert) {
            Button("Save & Exit") {
                Task {
                    await viewModel.saveProgress()
                    dismiss()
                }
            }
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Would you like to save your progress? You can continue this quiz later.")
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                // Back button
                Button(action: handleBackButton) {
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
                
                // Progress text
                if !viewModel.showConfirmation {
                    Text(viewModel.progressText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            
            // Quiz title
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(viewModel.quiz.gameIcon)
                        .font(.system(size: 20))
                    
                    Text(viewModel.quiz.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                if !viewModel.showConfirmation {
                    Text("\(viewModel.quiz.questions.count) questions • \(viewModel.quiz.estimatedMinutes) min")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            
            // Progress bar
            if !viewModel.showConfirmation {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.96, green: 0.62, blue: 0.04),
                                        Color(red: 1.0, green: 0.76, blue: 0.27)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * viewModel.progress, height: 6)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
        }
        .padding(.bottom, 24)
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
    }
    
    // MARK: - Question View
    
    private var questionView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Question card
                VStack(alignment: .leading, spacing: 20) {
                    // Question number and important badge
                    HStack {
                        Text("QUESTION \(viewModel.currentQuestionIndex + 1)")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            .tracking(1)
                        
                        if viewModel.currentQuestion.isImportant {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 9))
                                Text("IMPORTANT TO GAMERS")
                                    .font(.system(size: 9, weight: .black))
                                    .tracking(0.5)
                            }
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.15))
                            .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        if viewModel.currentQuestion.required {
                            Text("REQUIRED")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(0.5)
                        }
                    }
                    
                    // Question text
                    Text(viewModel.currentQuestion.questionText)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Answer options
                    answerOptionsView
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(red: 0.06, green: 0.06, blue: 0.06))
                        .shadow(color: .black.opacity(0.6), radius: 5, x: 5, y: 5)
                        .shadow(color: .white.opacity(0.02), radius: 5, x: -5, y: -5)
                )
                .padding(.horizontal, 24)
                
                // Navigation buttons
                navigationButtons
                
                Color.clear.frame(height: 40)
            }
        }
    }
    
    // MARK: - Answer Options View
    
    private var answerOptionsView: some View {
        VStack(spacing: 12) {
            let question = viewModel.currentQuestion
            
            ForEach(question.options, id: \.self) { option in
                let isSelected = viewModel.isOptionSelected(
                    questionId: question.id,
                    option: option
                )
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.toggleOption(
                            questionId: question.id,
                            option: option,
                            isMultipleChoice: question.questionType == .multipleChoice
                        )
                    }
                }) {
                    HStack(spacing: 14) {
                        // Icon based on question type
                        if question.questionType == .multipleChoice {
                            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                .font(.system(size: 22))
                                .foregroundColor(
                                    isSelected
                                        ? Color(red: 0.96, green: 0.62, blue: 0.04)
                                        : .white.opacity(0.3)
                                )
                        } else {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundColor(
                                    isSelected
                                        ? Color(red: 0.96, green: 0.62, blue: 0.04)
                                        : .white.opacity(0.3)
                                )
                        }
                        
                        Text(option)
                            .font(.system(size: 15))
                            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                isSelected
                                    ? Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.1)
                                    : Color.white.opacity(0.03)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected
                                    ? Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.3)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(QuizOptionButtonStyle())
            }
            
            // Multiple choice hint
            if question.questionType == .multipleChoice {
                Text("Select all that apply")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if viewModel.canGoBack {
                Button(action: {
                    slideDirection = .backward
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.goToPreviousQuestion()
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("Back")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.06, green: 0.06, blue: 0.06))
                            .shadow(color: .black.opacity(0.6), radius: 5, x: 3, y: 3)
                            .shadow(color: .white.opacity(0.02), radius: 5, x: -3, y: -3)
                    )
                }
            }
            
            Button(action: {
                slideDirection = .forward
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.goToNextQuestion()
                }
            }) {
                HStack {
                    Text(viewModel.isEditingFromConfirmation ? "Finish" : (viewModel.isLastQuestion ? "Review" : "Next"))
                        .font(.system(size: 15, weight: .bold))
                    if !viewModel.isEditingFromConfirmation {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundColor(viewModel.canGoNext ? .white : .white.opacity(0.3))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            viewModel.canGoNext
                                ? Color(red: 0.96, green: 0.62, blue: 0.04)
                                : Color.white.opacity(0.05)
                        )
                        .shadow(
                            color: viewModel.canGoNext
                                ? Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.3)
                                : .clear,
                            radius: 10,
                            y: 5
                        )
                )
            }
            .disabled(!viewModel.canGoNext)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Confirmation View
    
    private var confirmationView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Summary card
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("📋")
                            .font(.system(size: 48))
                        
                        Text("Review Your Answers")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(viewModel.answeredCount) of \(viewModel.quiz.questions.count) questions answered")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 12)
                    
                    // Questions list
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.quiz.questions.enumerated()), id: \.element.id) { index, question in
                            ConfirmationQuestionRow(
                                question: question,
                                questionNumber: index + 1,
                                answer: viewModel.getAnswer(for: question.id),
                                onEdit: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        viewModel.goToQuestion(at: index)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(red: 0.06, green: 0.06, blue: 0.06))
                        .shadow(color: .black.opacity(0.6), radius: 5, x: 5, y: 5)
                        .shadow(color: .white.opacity(0.02), radius: 5, x: -5, y: -5)
                )
                .padding(.horizontal, 24)
                
                // Submit button
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            let success = await viewModel.submitQuiz()
                            if success {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    showSubmitSuccess = true
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    dismiss()
                                }
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            }
                            Text(viewModel.isSubmitting ? "Submitting..." : "Submit Quiz")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    viewModel.requiredQuestionsAnswered
                                        ? Color(red: 0.96, green: 0.62, blue: 0.04)
                                        : Color.white.opacity(0.1)
                                )
                                .shadow(
                                    color: viewModel.requiredQuestionsAnswered
                                        ? Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.4)
                                        : .clear,
                                    radius: 15,
                                    y: 8
                                )
                        )
                    }
                    .disabled(!viewModel.requiredQuestionsAnswered || viewModel.isSubmitting)
                    
                    if !viewModel.requiredQuestionsAnswered {
                        Text("Please answer all required questions")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)
                
                Color.clear.frame(height: 40)
            }
        }
    }
    
    // MARK: - Success Overlay
    
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Checkmark animation
                ZStack {
                    Circle()
                        .fill(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                }
                .scaleEffect(showSubmitSuccess ? 1.0 : 0.5)
                .opacity(showSubmitSuccess ? 1.0 : 0)
                
                VStack(spacing: 8) {
                    Text("Quiz Submitted!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Your profile has been updated")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .opacity(showSubmitSuccess ? 1.0 : 0)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showSubmitSuccess)
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleBackButton() {
        if viewModel.showConfirmation {
            // Go back to last question
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                viewModel.showConfirmation = false
            }
        } else if viewModel.currentQuestionIndex > 0 {
            // Go to previous question
            slideDirection = .backward
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                viewModel.goToPreviousQuestion()
            }
        } else {
            // First question, show exit alert
            if viewModel.hasAnyAnswers {
                viewModel.showExitAlert = true
            } else {
                dismiss()
            }
        }
    }
}

// MARK: - Confirmation Question Row

struct ConfirmationQuestionRow: View {
    let question: QuizQuestion
    let questionNumber: Int
    let answer: QuizAnswer?
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            HStack(alignment: .top, spacing: 14) {
                // Question number badge
                Text("\(questionNumber)")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(
                        answer != nil
                            ? Color(red: 0.96, green: 0.62, blue: 0.04)
                            : .white.opacity(0.3)
                    )
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(
                                answer != nil
                                    ? Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.15)
                                    : Color.white.opacity(0.05)
                            )
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(question.questionText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let answer = answer, !answer.selectedOptions.isEmpty {
                        Text(answer.selectedOptions.joined(separator: ", "))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(question.required ? "Required - Not answered" : "Skipped")
                            .font(.system(size: 12))
                            .foregroundColor(question.required ? .red.opacity(0.8) : .white.opacity(0.4))
                    }
                }
                
                Spacer()
                
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
            )
        }
        .buttonStyle(QuizOptionButtonStyle())
    }
}

// MARK: - Button Styles

struct QuizOptionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
