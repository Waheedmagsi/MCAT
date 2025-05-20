import SwiftUI

struct DailyDrillView: View {
    @StateObject var viewModel: DailyDrillViewModel
    @EnvironmentObject var appRouter: AppRouter
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
            } else {
                contentView
            }
        }
        .navigationTitle("Daily Drill")
        .onAppear {
            viewModel.checkDailyDrillStatus()
        }
        .sheet(isPresented: $viewModel.showingDrill) {
            QuizView(viewModel: QuizViewModel(deckId: "daily", mode: .dailyDrill))
        }
        .alert("Premium Feature", isPresented: $viewModel.showingPremiumAlert) {
            Button("Upgrade", role: .cancel) {
                appRouter.showPremiumUpgrade()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Advanced daily drills with CAKT sequencing require a premium subscription.")
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 20) {
            // Header Illustration
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 70))
                .foregroundColor(.blue)
                .padding(.bottom, 10)
            
            // Daily Drill Info
            Text("Your Daily Drill")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(viewModel.dailyDrillDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
            
            // Stats
            HStack(spacing: 30) {
                StatItemView(value: "\(viewModel.questionCount)", label: "Questions")
                StatItemView(value: "\(viewModel.estimatedMinutes)", label: "Minutes")
                StatItemView(value: viewModel.targetSkill, label: "Focus")
            }
            .padding(.vertical, 15)
            .padding(.horizontal)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            
            // Action button
            if viewModel.drillAvailable {
                Button(action: {
                    viewModel.startDailyDrill()
                }) {
                    Text("Start Daily Drill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 20)
            } else {
                VStack {
                    Text("Next Drill Available In")
                        .font(.headline)
                    
                    Text(viewModel.nextDrillTime)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.vertical, 5)
                    
                    Button(action: {
                        viewModel.showPremiumFeatures()
                    }) {
                        Text("Get Premium for Extra Drills")
                            .font(.subheadline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    }
                    .padding(.top, 10)
                }
                .padding()
                .background(Color(.secondarySystemBackground).opacity(0.5))
                .cornerRadius(10)
            }
            
            Spacer()
                .frame(height: 20)
            
            // Recent performance
            if viewModel.hasCompletedDrills {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent Performance")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(viewModel.recentDrillStats) { stat in
                                DailyStatCard(stat: stat)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct StatItemView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct DailyStatCard: View {
    let stat: DailyDrillStat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stat.date)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("\(stat.score)%")
                    .font(.headline)
            }
            
            Text("\(stat.correct)/\(stat.total) correct")
                .font(.caption)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .frame(width: 120)
    }
}

struct DailyDrillView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DailyDrillView(viewModel: DailyDrillViewModel())
                .environmentObject(AppRouter())
        }
    }
} 