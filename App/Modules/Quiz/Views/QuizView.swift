import SwiftUI

struct QuizView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: QuizViewModel
    
    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Exit")
                    }
                }
            }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.status {
        case .loading:
            loadingView
        case .active:
            activeQuizView
        case .completed:
            completedView
        case .error(let message):
            errorView(message: message)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading questions...")
                .font(.headline)
        }
    }
    
    private var activeQuizView: some View {
        VStack(spacing: 0) {
            // Quiz header with progress and timer
            quizHeader
            
            // Question content
            if viewModel.isShowingExplanation {
                explanationView
            } else {
                questionView
            }
        }
    }
    
    private var quizHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.questions.count)")
                
                Spacer()
                
                Text(viewModel.formattedElapsedTime)
                    .font(.system(.subheadline, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(4)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundColor(Color(.systemGray5))
                        .frame(height: 4)
                    
                    Rectangle()
                        .foregroundColor(.blue)
                        .frame(width: geometry.size.width * CGFloat(viewModel.progressPercent), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
    
    private var questionView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Question text
                if let question = viewModel.currentQuestion {
                    Text(question.stemMarkdown)
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)
                
                    // Answer choices
                    VStack(spacing: 12) {
                        ForEach(question.choices, id: \.id) { choice in
                            ChoiceRow(
                                choice: choice,
                                isSelected: viewModel.selectedChoiceId == choice.id,
                                onTap: {
                                    viewModel.selectChoice(choiceId: choice.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Confidence slider
                    confidenceSlider
                    
                    // Submit button
                    Button(action: {
                        viewModel.submitAnswer()
                    }) {
                        Text("Submit Answer")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isSubmitEnabled ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!viewModel.isSubmitEnabled)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
            }
            .padding(.bottom, 30)
        }
    }
    
    private var explanationView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let question = viewModel.currentQuestion {
                    Text(question.stemMarkdown)
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    VStack(spacing: 12) {
                        ForEach(question.choices, id: \.id) { choice in
                            ChoiceResultRow(
                                choice: choice,
                                isSelected: viewModel.selectedChoiceId == choice.id
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical)
                    
                    Text("Explanation")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text(question.explanationMarkdown ?? "The correct answer is \(question.choices.first(where: { $0.isCorrect })?.text ?? ""). This concept often appears on the MCAT because it tests fundamental understanding of cellular energetics.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button(action: {
                        viewModel.moveToNextQuestion()
                    }) {
                        Text("Next Question")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
            .padding(.bottom, 30)
        }
    }
    
    private var confidenceSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How confident are you in your answer?")
                .font(.subheadline)
            
            HStack {
                Text("Not at all")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(value: $viewModel.confidenceLevel, in: 0...1, step: 0.05)
                
                Text("Very")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("\(Int(viewModel.confidenceLevel * 100))%")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var completedView: some View {
        QuizCompletionView(
            stats: viewModel.quizStats,
            onDismiss: {
                presentationMode.wrappedValue.dismiss()
            }
        )
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Text("Error Loading Questions")
                .font(.title)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                viewModel.loadQuestions()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button("Exit Quiz") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding(.top)
        }
        .padding()
    }
}

struct ChoiceRow: View {
    let choice: QuizChoice
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 16, height: 16)
                    }
                }
                .frame(width: 24, height: 24)
                
                Text("\(choice.id). \(choice.text)")
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 4)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                    .background(
                        isSelected ? Color.blue.opacity(0.1) : Color.clear
                    )
                    .cornerRadius(10)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ChoiceResultRow: View {
    let choice: QuizChoice
    let isSelected: Bool
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: choice.isCorrect ? "checkmark.circle.fill" : (isSelected ? "xmark.circle.fill" : "circle"))
                .foregroundColor(choice.isCorrect ? .green : (isSelected && !choice.isCorrect ? .red : .gray))
                .font(.headline)
                .frame(width: 24, height: 24)
            
            Text("\(choice.id). \(choice.text)")
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 4)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(choice.isCorrect ? Color.green : (isSelected && !choice.isCorrect ? Color.red : Color.gray), lineWidth: 2)
                .background(
                    (choice.isCorrect || (isSelected && !choice.isCorrect)) ? 
                        (choice.isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1)) : 
                        Color.clear
                )
                .cornerRadius(10)
        )
    }
}

struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        QuizView(viewModel: QuizViewModel(deckId: "deck1", mode: .deck))
    }
} 