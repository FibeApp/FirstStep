import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        startAppCoordinator()
    }

    private func startAppCoordinator() {
        let navigationController = UINavigationController()
        let router = RouterImpl(rootController: navigationController)
        let appCoordinator = AppCoordinator(router: router)
        self.appCoordinator = appCoordinator
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        appCoordinator.start()
    }
}

