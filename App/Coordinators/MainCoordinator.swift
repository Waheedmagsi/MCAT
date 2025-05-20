import SwiftUI

struct MainCoordinator: View {
    @ObservedObject var router: AppRouter
    
    var body: some View {
        TabView(selection: $router.currentTab) {
            NavigationView {
                DeckListView(viewModel: DeckListViewModel())
            }
            .tabItem {
                Label("Decks", systemImage: "rectangle.stack.fill")
            }
            .tag(AppTab.decks)
            
            NavigationView {
                DailyDrillView(viewModel: DailyDrillViewModel())
            }
            .tabItem {
                Label("Daily Drill", systemImage: "calendar.badge.clock")
            }
            .tag(AppTab.dailyDrill)
            
            NavigationView {
                DashboardView(viewModel: DashboardViewModel())
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.xyaxis.line")
            }
            .tag(AppTab.dashboard)
            
            NavigationView {
                ProfileView(viewModel: ProfileViewModel())
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(AppTab.profile)
        }
        .fullScreenCover(item: $router.activeFullExam) { examId in
            FullExamView(viewModel: FullExamViewModel(examId: examId))
        }
        .sheet(isPresented: $router.showingPremiumUpgrade) {
            PremiumUpgradeView(viewModel: PremiumUpgradeViewModel())
        }
    }
}

struct MainCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        MainCoordinator(router: AppRouter())
    }
} 