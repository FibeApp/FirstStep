import UIKit
import SnapKit

class AuthViewController: BaseViewController {
    private var store: AuthStore
    private var isLogin = true { didSet { updateUI() }}
    private var show = true { didSet { updateEyes() }}

    struct Model {
        let close: Callback?
    }

    private let model: Model
    init(store: AuthStore, model: Model) {
        self.store = store
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    private let emailTextField = AuthTextField(placeholder: "Email")
    private let passwordTextField = AuthTextField(placeholder: "Password", isSecureTextEntry: true)
    private let repeatTextField = AuthTextField(placeholder: "Repeat Password", isSecureTextEntry: true)

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
        config.cornerStyle = .medium
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
        let email = emailTextField.text
        let password = passwordTextField.text
        isLogin ? store.sendAction(.signIn(email, password)) : store.sendAction(.createUser(email, password))
    }

    @objc private func forgotButtonTapped() {
        let email = emailTextField.text
        store.sendAction(.sendPasswordReset(email))
    }

    @objc private func showChanged() {
        show.toggle()
    }

    private func updateEyes() {
        passwordTextField.configure(with: show)
        repeatTextField.configure(with: show)
    }
}
// MARK: - Setup Veiws
extension AuthViewController {
    override func setupViews() {
        super.setupViews()
        [rootStackView, actionButton, authStatusSwitch].forEach { view.addSubview($0)}
        authStatusSwitch.configure(self, action: #selector(authSwitchTapped))
        forgotButton.addTarget(self, action: #selector(forgotButtonTapped), for: .primaryActionTriggered)
        passwordTextField.configure(target: self, action: #selector(showChanged))
        repeatTextField.configure(target: self, action: #selector(showChanged))
        repeatTextField.isHidden = true
        actionButton.addTarget(
            self,
            action: #selector(actionButtonTapped),
            for: .primaryActionTriggered
        )
        [emailTextField, passwordTextField, repeatTextField, middleView]
            .forEach { rootStackView.addArrangedSubview($0)}
        middleView.addSubview(forgotButton)
        middleView.addSubview(resendButton)
        signOut()
        updateUI()
        setupObservers()
    }

    private func setupObservers() {
        store.loadingViewModel.$isLoading
            .sink { isLoading in
                if isLoading {
                    ProgressHUD.animate("Please wait")
                } else {
                    ProgressHUD.dismiss()
                }
            }.store(in: &bag)

        store.errorViewModel.$error
            .sink { error in
                if let error {
                    ProgressHUD.banner("Error!!!", error.localizedDescription)
                }
            }.store(in: &bag)
        store
            .events
            .receive(on: DispatchQueue.main)
            .sink {[weak self] event in
                guard let self else { return }
                switch event {
                case .registered:
                    ProgressHUD.succeed("Создали учетную запись, проверьте почту")
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
        navigationItem.title = isLogin ? "Login" : "Register"
        UIView.animate(withDuration: 0.5) {
            self.repeatTextField.isHidden = self.isLogin
            self.repeatTextField.alpha = self.isLogin ? 0 : 1
            self.middleView.isHidden = !self.isLogin
            self.middleView.alpha = self.isLogin ? 1 : 0
        }
    }

    override func setupConstraints() {
        super.setupConstraints()
        let padding = 20.0

        
        rootStackView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(50)
            $0.leading.trailing.equalToSuperview().inset(padding)
        }

        actionButton.snp.makeConstraints {
            $0.top.equalTo(rootStackView.snp.bottom).offset(50)
            $0.leading.trailing.equalToSuperview().inset(padding)
            $0.height.equalTo(50)
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
