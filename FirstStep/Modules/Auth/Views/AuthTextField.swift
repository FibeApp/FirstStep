import UIKit

final class AuthTextField: BaseView {
    private var placeholder = ""

    init(placeholder: String, isSecureTextEntry: Bool = false) {
        super.init(frame: .zero)
        textField.placeholder = placeholder
        if isSecureTextEntry {
            textField.rightView = showPasswordButton
            textField.rightViewMode = .always
            configure(with: true)
        } else {
            textField.isSecureTextEntry = false
        }
        self.placeholder = placeholder
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with isSecureTextEntry: Bool) {
        textField.isSecureTextEntry = isSecureTextEntry
        showPasswordButton.setImage(
            UIImage(systemName: isSecureTextEntry ? "eye" : "eye.slash"),
            for: []
        )
    }

    func configure(target: Any?, action: Selector) {
        showPasswordButton.addTarget(
            target,
            action: action,
            for: .primaryActionTriggered
        )
    }

    private let showPasswordButton: UIButton = {
        return $0
    }(UIButton(type: .system))


    private let label: UILabel = {
        $0.font = .systemFont(ofSize: 20)
        $0.textColor = .secondaryLabel
        return $0
    }(UILabel())

    private lazy var textField: UITextField = {
        $0.addTarget(
            self,
            action: #selector(textChanged),
            for: .editingChanged
        )
        $0.borderStyle = .none
        return $0
    }(UITextField())

    private let separator: UIView = {
        $0.backgroundColor = .secondaryLabel
        return $0
    }(UIView())

    var text: String {
        textField.text ?? ""
    }

    @objc func textChanged() {
        label.text = text.isEmpty ? "" : placeholder
    }

    func updateSecure(_ isSecureTextEntry: Bool) {
        textField.isSecureTextEntry = isSecureTextEntry
    }
}

extension AuthTextField {

    override func setupViews() {
        [label, textField, separator].forEach { addSubview($0)}
    }

    override func setupConstraints() {
        label.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(24)
        }

        textField.snp.makeConstraints {
            $0.top.equalTo(label.snp.bottom).offset(9)
            $0.leading.trailing.equalTo(label)
            $0.height.equalTo(24)
        }

        separator.snp.makeConstraints {
            $0.top.equalTo(textField.snp.bottom).offset(9)
            $0.leading.trailing.equalTo(label)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }
}

#Preview {
    AuthTextField(placeholder: "Email")
}
