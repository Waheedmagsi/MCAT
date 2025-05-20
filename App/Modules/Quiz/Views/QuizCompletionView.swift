import SwiftUI

struct QuizCompletionView: View {
    let stats: QuizSessionStats
    let onDismiss: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header with congrats message
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Quiz Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Great job on completing your study session")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical)
                
                // Score summary
                VStack(spacing: 15) {
                    ScoreSummaryView(percentage: stats.percentCorrect)
                    
                    HStack(spacing: 30) {
                        StatItem(label: "Questions", value: "\(stats.totalQuestions)")
                        StatItem(label: "Correct", value: "\(stats.correctAnswers)")
                        StatItem(label: "Incorrect", value: "\(stats.incorrectAnswers)")
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Time stats
                VStack(spacing: 8) {
                    Text("Performance")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        PerformanceStatView(
                            iconName: "clock.fill",
                            title: "Avg. Time",
                            value: formattedTime(seconds: stats.averageTimeSeconds),
                            color: .blue
                        )
                        
                        Divider()
                            .frame(height: 40)
                        
                        PerformanceStatView(
                            iconName: "chart.line.uptrend.xyaxis",
                            title: "Confidence",
                            value: "\(Int(stats.averageConfidence * 100))%",
                            color: .purple
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        // Dashboard action would go here
                        onDismiss()
                    }) {
                        Text("View Full Results")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // Return to deck
                        onDismiss()
                    }) {
                        Text("Return to Deck")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }
                }
                .padding()
            }
            .padding()
        }
    }
    
    private func formattedTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        } else {
            return "\(secs) sec"
        }
    }
}

struct ScoreSummaryView: View {
    let percentage: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 10)
                .frame(width: 120, height: 120)
            
            Circle()
                .trim(from: 0, to: CGFloat(min(percentage / 100, 1.0)))
                .stroke(scoreColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: percentage)
            
            VStack(spacing: 0) {
                Text("\(Int(percentage))%")
                    .font(.system(size: 30, weight: .bold))
                
                Text("Score")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 150)
    }
    
    private var scoreColor: Color {
        if percentage >= 70 {
            return .green
        } else if percentage >= 50 {
            return .yellow
        } else {
            return .red
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct PerformanceStatView: View {
    let iconName: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.headline)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuizCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        QuizCompletionView(
            stats: QuizSessionStats(
                totalQuestions: 10,
                answeredQuestions: 9,
                correctAnswers: 7,
                incorrectAnswers: 2,
                unansweredQuestions: 1,
                averageTimeSeconds: 45.7,
                averageConfidence: 0.75
            ),
            onDismiss: {}
        )
    }
} 