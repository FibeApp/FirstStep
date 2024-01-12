import Foundation
import FirebaseAuth

final class AppCoordinator: BaseCoordinator {
    override func start() {
        if let user = Auth.auth().currentUser, user.isEmailVerified {
            runMainModule()
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

    private func runMainModule() {
        let controller = makeMainModule()
        controller.view.backgroundColor = .systemGreen
        logout()
        router.setRootModule(controller)
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
        let model = AuthViewController.Model(close: { [weak self] in
            self?.start()
        })
        let controller = AuthViewController(store: store, model: model)
        return controller
    }

    private func makeMainModule() -> BaseViewControllerProtocol {
        let controller = BaseViewController()
        return controller
    }
}
