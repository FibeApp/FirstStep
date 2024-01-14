import UIKit

final class AuthStatusSwitch: BaseView {
    private let label = UILabel()
    private let button = UIButton(type: .system)
    private let stackView = UIStackView()

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
        stackView.spacing = 10
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(button)
    }

    override func setupConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
