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
            SecureField("Password", text: $password)
            TextField("Email", text: $email)
            Button("Register") {
                APIService.shared.register(username: username, password: password, email: email) { success in
                    if success {
                        isRegistered = true
                        errorMessage = ""
                    } else {
                        errorMessage = "Registration failed"
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