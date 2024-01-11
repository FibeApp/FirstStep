import FirebaseAuth

protocol AuthServiceProtocol {
    var isEmailVerified: Bool? { get }
    func createUser(withEmail email: String, password: String) async throws
    func login(withEmail email: String, password: String) async throws -> Bool
    func signOut() throws
}

extension FirebaseClient: AuthServiceProtocol {
    var isEmailVerified: Bool? {
        Auth.auth().currentUser?.isEmailVerified
    }
    func createUser(withEmail email: String, password: String) async throws {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        try await authResult.user.sendEmailVerification()
        try createPerson(withEmail: email, uid: authResult.user.uid)
    }

    func login(withEmail email: String, password: String) async throws -> Bool {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user.isEmailVerified
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
