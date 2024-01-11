import Foundation
import FirebaseAuth

final class AppCoordinator: BaseCoordinator {
    override func start() {
        if let user = Auth.auth().currentUser, user.isEmailVerified {
            print("Show main screen")
        } else {
            runModule()
        }
    }

    private func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print(error.localizedDescription)
        }
    }

    private func runModule() {
        let controller = makeModule()
        router.setRootModule(controller)
    }
}

extension AppCoordinator {
    private func makeModule() -> BaseViewControllerProtocol {
        let useCase = AuthUseCase(apiService: FirebaseClient.shared)
        let store = AuthStore(useCase: useCase)
        let model = AuthViewController.Model(close: {
            print("Yes")
        })
        let controller = AuthViewController(store: store, model: model)
        return controller
    }
}
