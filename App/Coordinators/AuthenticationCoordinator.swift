import SwiftUI

struct AuthenticationCoordinator: View {
    @ObservedObject var router: AppRouter
    @StateObject private var viewModel = AuthenticationViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // App logo
                Image(systemName: "brain.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.bottom, 40)
                
                Text("MCATPrep")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 40)
                
                // Authentication options
                VStack(spacing: 16) {
                    Button(action: {
                        viewModel.signInWithApple()
                    }) {
                        HStack {
                            Image(systemName: "apple.logo")
                                .font(.title2)
                            Text("Sign in with Apple")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    }
                    
                    Button(action: {
                        viewModel.signInWithGoogle()
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                            Text("Sign in with Google")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    }
                    
                    Button(action: {
                        viewModel.showEmailForm.toggle()
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.title2)
                            Text("Sign in with Email")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Terms of service
                Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showEmailForm) {
                EmailAuthView(onComplete: { success in
                    if success {
                        router.isAuthenticated = true
                    }
                })
            }
        }
        .onReceive(viewModel.$authenticationState) { state in
            if state == .authenticated {
                router.isAuthenticated = true
            }
        }
    }
}

struct EmailAuthView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let onComplete: (Bool) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Email Authentication")) {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: {
                        authenticate()
                    }) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text(isSignUp ? "Sign Up" : "Sign In")
                        }
                    }
                    .disabled(isLoading || !isValidInput)
                }
                
                Section {
                    Button(action: {
                        isSignUp.toggle()
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Need an account? Sign Up")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationBarTitle(isSignUp ? "Create Account" : "Sign In", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private var isValidInput: Bool {
        !email.isEmpty && password.count >= 6
    }
    
    private func authenticate() {
        isLoading = true
        errorMessage = nil
        
        // Simulate authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            // Mock success
            onComplete(true)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

class AuthenticationViewModel: ObservableObject {
    enum AuthState {
        case unauthenticated
        case authenticating
        case authenticated
    }
    
    @Published var authenticationState: AuthState = .unauthenticated
    @Published var showEmailForm = false
    
    func signInWithApple() {
        authenticationState = .authenticating
        
        // Simulate Apple authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.authenticationState = .authenticated
        }
    }
    
    func signInWithGoogle() {
        authenticationState = .authenticating
        
        // Simulate Google authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.authenticationState = .authenticated
        }
    }
}

struct AuthenticationCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationCoordinator(router: AppRouter())
    }
} 