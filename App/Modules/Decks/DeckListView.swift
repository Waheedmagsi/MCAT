import SwiftUI

struct DeckListView: View {
    @ObservedObject var viewModel: DeckListViewModel
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
            } else {
                contentView
            }
        }
        .navigationTitle("MCAT Decks")
        .onAppear {
            viewModel.loadDecks()
        }
        .refreshable {
            await viewModel.refreshDecks()
        }
    }
    
    private var contentView: some View {
        Group {
            if viewModel.decks.isEmpty {
                emptyStateView
            } else {
                deckListView
            }
        }
    }
    
    private var deckListView: some View {
        List {
            ForEach(viewModel.filteredDecks) { deck in
                NavigationLink(destination: DeckDetailView(viewModel: DeckDetailViewModel(deck: deck))) {
                    DeckRowView(deck: deck)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .searchable(text: $searchText, prompt: "Search decks")
        .onChange(of: searchText) { newValue in
            viewModel.filterDecks(with: newValue)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack.badge.xmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Decks Available")
                .font(.title)
                .fontWeight(.medium)
            
            Text("Decks will appear here once they're available")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Refresh") {
                Task {
                    await viewModel.refreshDecks()
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

struct DeckRowView: View {
    let deck: DeckViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(deck.title)
                .font(.headline)
            
            Text("\(deck.questionCount) questions")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let masteryPercentage = deck.masteryPercentage {
                HStack {
                    Text("Mastery:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: masteryPercentage, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: masteryColor(for: masteryPercentage)))
                    
                    Text("\(Int(masteryPercentage))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
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

struct DeckListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeckListView(viewModel: DeckListViewModel())
        }
    }
} 