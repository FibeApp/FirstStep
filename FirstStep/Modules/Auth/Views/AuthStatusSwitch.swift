import UIKit

final class AuthStatusSwitch: BaseView {
    private let label: UILabel = {
        return $0
    }(UILabel())

    private let button: UIButton = {
        return $0
    }(UIButton(type: .system))

    private let stackView: UIStackView = {
        $0.spacing = 10
        return $0
    }(UIStackView())

    func configure(with isLogin: Bool) {
        label.text = isLogin ? "Don't have an account?" : "Already have an account?"
        button.setTitle(isLogin ? "Register" : "Login", for: [])
    }

    func configure(_ target: Any?, action: Selector) {
        button.addTarget(target, action: action, for: .primaryActionTriggered)
    }
}
// MARK: - Setup Views
extension AuthStatusSwitch {
    override func setupViews() {
        addSubview(stackView)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(button)
    }

    override func setupConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
