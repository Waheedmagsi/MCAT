import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overall score card
                overallScoreCard
                
                // Activity stats
                activityStatsCard
                
                // Topics mastery
                masteryHeatmapCard
                
                // Percentile ranking
                if let percentile = viewModel.percentileRank {
                    percentileCard(percentile: percentile)
                }
                
                // Streak and consistency
                streakCard
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .onAppear {
            viewModel.loadDashboardData()
        }
        .refreshable {
            await viewModel.refreshDashboardData()
        }
    }
    
    private var overallScoreCard: some View {
        VStack(spacing: 15) {
            Text("Overall Mastery")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .center, spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(min(viewModel.overallMastery / 100, 1.0)))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .green]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("\(Int(viewModel.overallMastery))%")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let scoreChange = viewModel.masteryChange {
                            HStack(spacing: 2) {
                                Image(systemName: scoreChange >= 0 ? "arrow.up" : "arrow.down")
                                    .foregroundColor(scoreChange >= 0 ? .green : .red)
                                    .font(.caption)
                                
                                Text("\(abs(scoreChange))%")
                                    .foregroundColor(scoreChange >= 0 ? .green : .red)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target: 515+")
                        .font(.headline)
                    
                    Text("On track for your goal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Keep up the good work!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading)
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    private var activityStatsCard: some View {
        VStack(spacing: 15) {
            Text("Your Activity")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                StatBox(
                    value: "\(viewModel.questionsAnswered)",
                    label: "Questions",
                    color: .blue,
                    icon: "questionmark.circle.fill"
                )
                
                Divider()
                
                StatBox(
                    value: "\(viewModel.studyStreak)",
                    label: "Day Streak",
                    color: .orange,
                    icon: "flame.fill"
                )
                
                Divider()
                
                StatBox(
                    value: "\(viewModel.hoursStudied)",
                    label: "Hours",
                    color: .purple,
                    icon: "clock.fill"
                )
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    private var masteryHeatmapCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Topic Mastery")
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    Button("All Topics", action: { viewModel.filterTopics(filter: .all) })
                    Button("Weakest", action: { viewModel.filterTopics(filter: .weakest) })
                    Button("Strongest", action: { viewModel.filterTopics(filter: .strongest) })
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        .font(.subheadline)
                }
            }
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.topicMastery) { topic in
                        HStack {
                            Text(topic.name)
                                .font(.subheadline)
                                .lineLimit(1)
                                .frame(width: 120, alignment: .leading)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .frame(height: 20)
                                        .foregroundColor(Color(.systemGray5))
                                        .cornerRadius(5)
                                    
                                    Rectangle()
                                        .frame(width: geometry.size.width * CGFloat(topic.mastery / 100), height: 20)
                                        .foregroundColor(masteryColor(for: topic.mastery))
                                        .cornerRadius(5)
                                    
                                    HStack {
                                        Spacer()
                                        Text("\(Int(topic.mastery))%")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.trailing, 8)
                                    }
                                    .frame(height: 20)
                                }
                            }
                            .frame(height: 20)
                        }
                    }
                }
            }
            .frame(height: 250)
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    private func percentileCard(percentile: Int) -> some View {
        VStack(spacing: 15) {
            Text("Your MCAT Percentile")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                Text("\(percentile)th")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                
                Text("Percentile")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("You're performing better than \(percentile)% of MCAT test takers based on your practice results.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    private var streakCard: some View {
        VStack(spacing: 15) {
            Text("Study Consistency")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    let isActive = viewModel.weeklyActivity[dayIndex]
                    VStack(spacing: 4) {
                        Circle()
                            .fill(isActive ? Color.green : Color(.systemGray5))
                            .frame(width: 20, height: 20)
                        
                        Text(viewModel.weekdayLabels[dayIndex])
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    private func masteryColor(for percentage: Double) -> Color {
        switch percentage {
        case 0..<40:
            return .red
        case 40..<60:
            return .orange
        case 60..<80:
            return .yellow
        default:
            return .green
        }
    }
}

struct StatBox: View {
    let value: String
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DashboardView(viewModel: DashboardViewModel())
        }
    }
} 