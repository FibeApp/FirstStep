import UIKit

extension UINavigationController {
    func replaceTopViewController(with viewController: UIViewController, animated: Bool = true) {
        guard viewControllers.count > 0 else { return }
        var newViewControllers = viewControllers
        let index = newViewControllers.count - 1
        newViewControllers[index] = viewController
        setViewControllers(newViewControllers, animated: animated)
    }
}
