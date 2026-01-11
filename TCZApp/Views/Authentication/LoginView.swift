import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo/Header
                    VStack(spacing: 8) {
                        Image(systemName: "sportscourt")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("Tennis Club Zollikon")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Platzbuchung")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)

                    // Login Form
                    VStack(spacing: 16) {
                        TextField("E-Mail", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .email)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        SecureField("Passwort", text: $password)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Button(action: login) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Anmelden")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canLogin ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!canLogin)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            case .password:
                login()
            case .none:
                break
            }
        }
    }

    private var canLogin: Bool {
        !authViewModel.isLoading && !email.isEmpty && !password.isEmpty
    }

    private func login() {
        focusedField = nil
        Task {
            await authViewModel.login(email: email, password: password)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
