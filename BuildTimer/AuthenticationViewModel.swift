import SwiftUI
import Firebase

class AuthenticationViewModel: ObservableObject {
    @Published var user: User?
    
    func signInAnonymously() {
        Auth.auth().signInAnonymously { (authResult, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let authResult = authResult else { return }
            self.user = authResult.user
        }
    }
}
