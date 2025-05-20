import SwiftUI

struct DeckDetailView: View {
    @ObservedObject var viewModel: DeckDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appRouter: AppRouter
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                
                statsSection
                
                descriptionSection
                
                actionSection
            }
            .padding()
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadDeckDetails()
        }
        .sheet(isPresented: $viewModel.showingQuiz) {
            QuizView(viewModel: QuizViewModel(deckId: viewModel.deckId, mode: .deck))
        }
        .alert("Premium Feature", isPresented: $viewModel.showingPremiumAlert) {
            Button("Upgrade", role: .cancel) {
                appRouter.showPremiumUpgrade()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This feature requires a premium subscription.")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("\(viewModel.questionCount) Questions")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let conceptName = viewModel.conceptName {
                Text("Concept: \(conceptName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.headline)
            
            if let masteryPercentage = viewModel.masteryPercentage {
                HStack {
                    Text("Mastery:")
                    
                    ProgressView(value: masteryPercentage, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: masteryColor(for: masteryPercentage)))
                    
                    Text("\(Int(masteryPercentage))%")
                }
                
                if let lastPracticed = viewModel.lastPracticed {
                    Text("Last practiced: \(lastPracticed)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("You haven't practiced this deck yet.")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About this deck")
                .font(.headline)
            
            Text(viewModel.description)
                .foregroundColor(.secondary)
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                viewModel.startPractice()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Practice Session")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Button(action: {
                viewModel.startAdaptiveExam()
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Adaptive Exam")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .foregroundColor(.primary)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 1)
                )
            }
            
            if let questionsAttempted = viewModel.questionsAttempted, questionsAttempted > 0 {
                Button(action: {
                    viewModel.reviewMistakes()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Review Mistakes")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
            }
        }
        .padding(.top, 10)
    }
    
    private func masteryColor(for percentage: Double) -> Color {
        switch percentage {
        case 0..<30:
            return .red
        case 30..<70:
            return .yellow
        default:
            return .green
        }
    }
}

struct DeckDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeckDetailView(viewModel: DeckDetailViewModel(deck: DeckViewModel(
                id: "deck1",
                title: "Biology Foundations",
                questionCount: 50,
                masteryPercentage: 78
            )))
        }
    }
} 