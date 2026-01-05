import SwiftUI

struct RegisterView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var errorMessage = ""
    @State private var isRegistered = false
    
    var body: some View {
        VStack {
            TextField("Username", text: $username)
                .autocapitalization(.none)
            SecureField("Password", text: $password)
                .autocapitalization(.none)
            TextField("Email", text: $email)
                .autocapitalization(.none)
            Button("Register") {
                // Input validation
                guard !username.isEmpty else {
                    errorMessage = "Username cannot be empty"
                    return
                }
                guard !password.isEmpty else {
                    errorMessage = "Password cannot be empty"
                    return
                }
                guard !email.isEmpty else {
                    errorMessage = "Email cannot be empty"
                    return
                }
                guard email.contains("@") && email.contains(".") else {
                    errorMessage = "Invalid email format"
                    return
                }
                
                print("[RegisterView] Register button tapped with username: \(username), email: \(email)")
                APIService.shared.register(username: username, password: password, email: email) { success, error in
                    print("[RegisterView] Register API response: success=\(success)")
                    if success {
                        print("[RegisterView] Registration successful")
                        isRegistered = true
                        errorMessage = ""
                    } else {
                        print("[RegisterView] Registration failed: \(error ?? "Unknown error")")
                        errorMessage = error ?? "Registration failed"
                    }
                }
            }
            if isRegistered {
                Text("Registered! Now log in.")
            }
            Text(errorMessage).foregroundColor(.red)
        }.padding()
    }
}
