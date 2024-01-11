import Foundation

enum AuthEvent {
    case registered
    case emailVerified
    case notVerified
}

enum AuthAction {
    case createUser(String, String)
    case login(String, String)
    case signOut
}

final class AuthStore: Store<AuthEvent, AuthAction> {
    private let useCase: AuthUseCase

    init(useCase: AuthUseCase) {
        self.useCase = useCase
    }

    override func handleActions(action: AuthAction) {
        switch action {
        case .createUser(let email, let password):
            statefulCall { [weak self] in
                try await self?.register(
                    withEmail: email,
                    password: password
                )
            }
        case .login(let email, let password):
            statefulCall { [weak self] in
                try await self?.login(
                    withEmail: email,
                    password: password
                )
            }
        case .signOut: signOut()
        }
    }

    private func register(withEmail email: String, password: String) async throws {
        try await useCase.createUser(withEmail: email, password: password)
        sendEvent(.registered)
    }

    private func login(withEmail email: String, password: String) async throws {
        let response = try await useCase.login(withEmail: email, password: password)
        try checkResponse(response)
    }

    private func emailVerification() throws {
        guard let response = useCase.isEmailVerified else { return }
        try checkResponse(response)
    }

    private func checkResponse(_ response: Bool) throws {
        if response {
            sendEvent(.emailVerified)
        } else {
            signOut()
            sendEvent(.notVerified)
        }
    }

    private func signOut() {
        do {
            try useCase.signOut()
        } catch {
            print(error.localizedDescription)
        }
    }
}
