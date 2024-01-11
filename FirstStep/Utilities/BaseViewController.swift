import UIKit

class BaseViewController: UIViewController, BaseViewControllerProtocol {
    var bag = Bag()
    var onRemoveFromNavigationStack: (() -> Void)?
    var onDidDismiss: (() -> Void)?
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil { onRemoveFromNavigationStack?() }
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) { [weak self] in
            completion?()
            self?.onDidDismiss?()
        }
    }

    deinit {
        print("\(String(describing: self)) dealloc" )
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }
}

@objc extension BaseViewController {
    func setupViews() {
        view.backgroundColor = .systemBackground
    }
    func setupConstraints() {}
}
