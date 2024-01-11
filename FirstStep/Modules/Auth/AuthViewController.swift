import UIKit
import SnapKit

class AuthViewController: BaseViewController {
    private var store: AuthStore
    private var isLogin = true { didSet { updateUI() }}
    struct Model {
        let close: Callback?
    }

    private let model: Model
    init(store: AuthStore, model: Model) {
        self.store = store
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    private let titleLabel: UILabel = {
        $0.textAlignment = .center
        $0.font = .systemFont(ofSize: 35)
        return $0
    }(UILabel())

    private let emailTextField: UITextField = {
        $0.placeholder = "Email"
        $0.borderStyle = .roundedRect
        return $0
    }(UITextField())

    private let passwordTextField: UITextField = {
        $0.placeholder = "Password"
        $0.isSecureTextEntry = true
        $0.borderStyle = .roundedRect
        return $0
    }(UITextField())

    private let repeatTextField: UITextField = {
        $0.placeholder = "Repeat Password"
        $0.isSecureTextEntry = true
        $0.borderStyle = .roundedRect
        $0.isHidden = true
        $0.isEnabled = false
        $0.alpha = 0
        return $0
    }(UITextField())

    private let forgotButton: UIButton = {
        $0.contentHorizontalAlignment = .leading
        $0.setTitle("Forgot Password?", for: [])
        return $0
    }(UIButton(type: .system))

    private let resendButton: UIButton = {
        $0.contentHorizontalAlignment = .trailing
        $0.isHidden = true
        $0.setTitle("Resend Email", for: [])
        return $0
    }(UIButton(type: .system))

    private let middleView = UIView()

    private let actionButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Login"
        config.baseBackgroundColor = .systemRed
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        $0.configuration = config
        return $0
    }(UIButton(type: .system))

    private let authStatusSwitch = AuthStatusSwitch()

    private let rootStackView: UIStackView = {
        $0.axis = .vertical
        $0.spacing = 10
        return $0
    }(UIStackView())

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
// MARK: - Actions
extension AuthViewController {
    public func signOut() {
        store.sendAction(.signOut)
    }
    
    @objc private func authSwitchTapped() {
        isLogin.toggle()
    }

    @objc private func actionButtonTapped() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty
        else { return }
        isLogin ? store.sendAction(.signIn(email, password)) : store.sendAction(.createUser(email, password))
    }

    @objc private func forgotButtonTapped() {
        guard let email = emailTextField.text else { return }
        store.sendAction(.sendPasswordReset(email))
    }
}
// MARK: - Setup Veiws
extension AuthViewController {
    override func setupViews() {
        super.setupViews()
        view.addSubview(titleLabel)
        view.addSubview(rootStackView)
        view.addSubview(authStatusSwitch)
        authStatusSwitch.configure(self, action: #selector(authSwitchTapped))
        forgotButton.addTarget(self, action: #selector(forgotButtonTapped), for: .primaryActionTriggered)
        actionButton.addTarget(
            self,
            action: #selector(actionButtonTapped),
            for: .primaryActionTriggered
        )
        [emailTextField, passwordTextField, repeatTextField, middleView, actionButton]
            .forEach { rootStackView.addArrangedSubview($0)}
        middleView.addSubview(forgotButton)
        middleView.addSubview(resendButton)
        signOut()
        updateUI()
        setupObservers()
    }

    private func setupObservers() {
        store
            .events
            .receive(on: DispatchQueue.main)
            .sink {[weak self] event in
                guard let self else { return }
                switch event {
                case .registered:
                    print("Создали учетную запись, проверьте почту")
                    self.isLogin = true
                case .emailVerified:
                    self.model.close?()
                case .notVerified:
                    print("не проверено")
                case .linkSended:
                    print("проверьте почту")
                }
            }.store(in: &bag)
    }

    private func updateUI() {
        authStatusSwitch.configure(with: isLogin)
        actionButton.configuration?.title = isLogin ? "Login" : "Register"
        titleLabel.text = isLogin ? "Login" : "Register"
        UIView.animate(withDuration: 0.5) {
            self.repeatTextField.isHidden = self.isLogin
            self.repeatTextField.alpha = self.isLogin ? 0 : 1
        }
    }

    override func setupConstraints() {
        super.setupConstraints()
        let padding = 20.0

        titleLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(padding)
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(50)
        }
        rootStackView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(padding)
        }

        authStatusSwitch.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(50)
        }

        forgotButton.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
        }

        resendButton.snp.makeConstraints {
            $0.top.bottom.equalTo(forgotButton)
            $0.trailing.equalToSuperview()
            $0.leading.equalTo(forgotButton.snp.trailing)
            $0.width.equalTo(forgotButton.snp.width)
        }
    }
}
