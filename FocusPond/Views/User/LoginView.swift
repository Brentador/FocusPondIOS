import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            TextField("Username", text: $username)
                .autocapitalization(.none)
            SecureField("Password", text: $password)
            Button("Login") {
                APIService.shared.login(username: username, password: password) { response in
                    if let response = response, response.status == "success" {
                        AuthService.shared.login(userId: response.user_id, username: username)
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        errorMessage = "Login failed"
                    }
                }
            }
            Text(errorMessage).foregroundColor(.red)
            NavigationLink("Don't have an account? Register", destination: RegisterView())
        }.padding()
    }
}
