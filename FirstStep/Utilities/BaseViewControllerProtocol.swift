import UIKit

public protocol BaseViewControllerProtocol: UIViewController {
    var onRemoveFromNavigationStack: (() -> Void)? { get set }
    var onDidDismiss: (() -> Void)? { get set }
}
