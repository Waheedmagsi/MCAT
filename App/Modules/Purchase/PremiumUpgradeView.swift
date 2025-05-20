import SwiftUI

// Placeholder ViewModel
class PremiumUpgradeViewModel: ObservableObject {
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var isLoading = false
    @Published var premiumFeatures: [String] = [
        "Unlimited Full-Length Exams",
        "AI-Powered Explanations",
        "CAKT Advanced Sequencing",
        "Offline Daily Drills"
    ]
    @Published var subscriptionOptions: [SubscriptionOption] = [
        SubscriptionOption(id: "monthly", title: "Monthly Plan", description: "Billed every month", price: "$19.99/mo", savings: 0),
        SubscriptionOption(id: "annual", title: "Annual Plan", description: "Billed annually", price: "$119.99/yr", savings: 40)
    ]
    @Published var selectedOption: SubscriptionOption? = nil

    func loadProducts() { print("VM: Load products") }
    func selectOption(_ option: SubscriptionOption) { self.selectedOption = option }
    func purchaseSelected() { print("VM: Purchase selected") }
}

struct SubscriptionOption: Identifiable {
    let id: String
    let title: String
    let description: String
    let price: String
    let savings: Int // Percentage
}

struct PremiumUpgradeView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: PremiumUpgradeViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    headerView
                    
                    // Features list
                    featuresView
                    
                    // Subscription options
                    subscriptionOptionsView
                    
                    // Purchase button
                    purchaseButton
                    
                    // Terms and conditions
                    termsText
                }
                .padding()
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $viewModel.showingAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .overlay(
                Group {
                    if viewModel.isLoading {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(2)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            )
                    }
                }
            )
        }
        .onAppear {
            viewModel.loadProducts()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 15) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            Text("Upgrade to Premium")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Get unlimited access to all features and maximize your MCAT prep")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding(.top)
    }
    
    private var featuresView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Premium Features")
                .font(.headline)
                .padding(.bottom, 5)
            
            ForEach(viewModel.premiumFeatures, id: \.self) { feature in
                HStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text(feature)
                        .font(.subheadline)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var subscriptionOptionsView: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.subscriptionOptions) { option in
                Button(action: {
                    viewModel.selectOption(option)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.title)
                                .font(.headline)
                            
                            Text(option.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(option.price)
                                .font(.headline)
                            
                            if option.savings > 0 {
                                Text("Save \(option.savings)%")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        if viewModel.selectedOption?.id == option.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .padding(.leading, 8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(viewModel.selectedOption?.id == option.id ? Color.blue : Color.gray, lineWidth: 2)
                            .background(
                                viewModel.selectedOption?.id == option.id ? Color.blue.opacity(0.1) : Color.clear
                            )
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var purchaseButton: some View {
        Button(action: {
            viewModel.purchaseSelected()
        }) {
            Text("Start Premium Now")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
        .disabled(viewModel.selectedOption == nil || viewModel.isLoading)
        .padding(.vertical)
    }
    
    private var termsText: some View {
        Text("By subscribing, you agree to our Terms of Service and Privacy Policy. Your subscription will automatically renew unless canceled at least 24 hours before the end of the current period. You can manage your subscription in your App Store account settings.")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.bottom)
    }
}

struct PremiumUpgradeView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumUpgradeView(viewModel: PremiumUpgradeViewModel())
    }
} 