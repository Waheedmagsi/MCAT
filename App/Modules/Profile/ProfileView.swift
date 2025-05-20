import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @EnvironmentObject var appRouter: AppRouter
    
    var body: some View {
        List {
            // User info section
            Section {
                HStack(spacing: 15) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.userName)
                            .font(.headline)
                        
                        Text(viewModel.userEmail)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if viewModel.isPremium {
                            Text("Premium Member")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                                .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            // Subscription section
            Section(header: Text("Subscription")) {
                if viewModel.isPremium {
                    HStack {
                        Text("Premium Plan")
                        Spacer()
                        Text(viewModel.subscriptionTier)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Renews")
                        Spacer()
                        Text(viewModel.renewalDate ?? "N/A")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button(action: {
                        appRouter.showPremiumUpgrade()
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Upgrade to Premium")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // Settings section
            Section(header: Text("Settings")) {
                Button(action: {
                    viewModel.toggleNotifications()
                }) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.blue)
                        Text("Notifications")
                        Spacer()
                        Toggle("", isOn: $viewModel.notificationsEnabled)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: Text("Study Goals")) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.blue)
                        Text("Study Goals")
                    }
                }
                
                NavigationLink(destination: Text("App Settings")) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                        Text("App Settings")
                    }
                }
            }
            
            // Support section
            Section(header: Text("Support")) {
                Button(action: {
                    viewModel.contactSupport()
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.blue)
                        Text("Help & Support")
                    }
                }
                
                Button(action: {
                    viewModel.openPrivacyPolicy()
                }) {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.blue)
                        Text("Privacy Policy")
                    }
                }
                
                Button(action: {
                    viewModel.openTermsOfService()
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        Text("Terms of Service")
                    }
                }
            }
            
            // Sign out section
            Section {
                Button(action: {
                    viewModel.signOut()
                }) {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Profile")
        .onAppear {
            viewModel.loadUserProfile()
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView(viewModel: ProfileViewModel())
                .environmentObject(AppRouter())
        }
    }
} 