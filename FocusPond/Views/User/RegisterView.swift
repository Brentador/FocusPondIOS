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
                print("[RegisterView] Register button tapped with username: \(username), email: \(email)")
                APIService.shared.register(username: username, password: password, email: email) { success in
                    print("[RegisterView] Register API response: success=\(success)")
                    if success {
                        print("[RegisterView] Registration successful")
                        isRegistered = true
                        errorMessage = ""
                    } else {
                        print("[RegisterView] Registration failed")
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
