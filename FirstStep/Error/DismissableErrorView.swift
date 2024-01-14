import Combine
import SwiftUI

struct WithError: ViewModifier {
    @EnvironmentObject var errorViewModel: ErrorViewModel

    func body(content: Content) -> some View {
        if errorViewModel.error != nil {
            content
                .overlay(
                    ErrorView(viewModel: errorViewModel)
                )
        } else {
            content
        }
    }
}

struct WithDismissableError: ViewModifier {
    @EnvironmentObject var errorViewModel: ErrorViewModel

    func body(content: Content) -> some View {
        if errorViewModel.error != nil {
            content
                .overlay(
                    DismissableErrorView(
                        viewModel: errorViewModel,
                        onDismiss: {
                            errorViewModel.error = nil
                        }
                    )
                )
        } else {
            content
        }
    }
}

extension View {
    func withError() -> some View {
        modifier(WithError())
    }

    func withDismissableError() -> some View {
        modifier(WithDismissableError())
    }
}

struct DismissableErrorView: View {
    @ObservedObject var viewModel: ErrorViewModel
    let onDismiss: Callback

    var body: some View {
        if let error = viewModel.error {
            VStack(spacing: 20) {
                Image(error.imageName)
                    .frame(width: 100, height: 100)
                Text(error.message)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if error.isRetryable {
                    Button("Повторить снова") {
                        viewModel.onRetry()
                    }.buttonStyle(.borderedProminent)
                }
                Button("Отмена") {
                    onDismiss()
                }.buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { Color.white }
        }
    }
}

struct ErrorView: View {
    @ObservedObject var viewModel: ErrorViewModel

    var body: some View {
        if let error = viewModel.error {
            VStack(spacing: 20) {
                Spacer()
                Image(error.imageName)
                    .frame(width: 100, height: 100)
                Text(error.message)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if error.isRetryable {
                    Button("Повторить снова") {
                        viewModel.onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { Color.white }
        }
    }
}

extension View {
    func bindError(from errorViewModel: ErrorViewModel) -> some View {
        environmentObject(errorViewModel)
    }

    func bindError(from errorObservable: ErrorObservable) -> some View {
        environmentObject(errorObservable.errorViewModel)
    }
}

extension UIViewController {
    func bindError(to view: UIView, from errorObservable: ErrorObservable) -> AnyCancellable {
        bindError(to: view, from: errorObservable.errorViewModel)
    }

    func bindError(to view: UIView, from errorViewModel: ErrorViewModel) -> AnyCancellable {
        let errorView = UIKitErrorView(errorViewModel: errorViewModel)
        errorView.view.alpha = 0
        addIgnoringSafeArea(errorView, to: view)

        return errorViewModel
            .$error
            .receiveOnMainQueue()
            .sink { [weak self] error in
                guard let self = self else { return }
                if error.exists {
                    self.view.bringSubviewToFront(errorView.view)
                    errorView.view.alpha = 1
                } else {
                    errorView.view.alpha = 0
                }
            }
    }

    func bindDismissableError(to view: UIView, from errorViewModel: ErrorViewModel) -> AnyCancellable {
        let errorView = UIKitDismissableErrorView(errorViewModel: errorViewModel)
        errorView.view.alpha = 0
        add(errorView, to: view)

        return errorViewModel
            .$error
            .receiveOnMainQueue()
            .sink { [weak self] error in
                guard let self = self else { return }
                if error.exists {
                    self.view.bringSubviewToFront(errorView.view)
                    errorView.view.alpha = 1
                } else {
                    errorView.view.alpha = 0
                }
            }
    }
}

final class UIKitErrorView: UIViewController {
    var errorViewModel: ErrorViewModel

    private lazy var rootView: BridgedView = ErrorView(viewModel: errorViewModel).bridge()

    init(errorViewModel: ErrorViewModel) {
        self.errorViewModel = errorViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        addIgnoringSafeArea(rootView)
    }
}

final class UIKitDismissableErrorView: UIViewController {
    var errorViewModel: ErrorViewModel

    private lazy var rootView: BridgedView = {
        DismissableErrorView(
            viewModel: errorViewModel,
            onDismiss: { [weak self] in
                guard let self = self else { return }
                self.errorViewModel.error = nil
            }
        )
        .bridge()
    }()

    init(errorViewModel: ErrorViewModel) {
        self.errorViewModel = errorViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        addBridgedViewAsRoot(rootView)
    }
}

typealias BridgedView = UIViewController

extension View {
    public func bridge() -> UIHostingController<Self> {
        RestrictedUIHostingController(rootView: self).apply { vc in
            vc.view.backgroundColor = .clear
        }
    }

    public func bridgeAndApply(_ configurator: (UIView) -> Void) -> UIHostingController<Self> {
        bridge().apply { vc in
            configurator(vc.view)
        }
    }
}

public class BridgingCollectionReusableView<Content: View>: UICollectionReusableView {
    private var hostingController = RestrictedUIHostingController<Content?>(rootView: nil)

    override public init(frame: CGRect) {
        super.init(frame: frame)
        clearBackgroundColors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        hostingController.willMove(toParent: nil)
        hostingController.view.removeFromSuperview()
        hostingController.removeFromParent()
        hostingController = RestrictedUIHostingController<Content?>(rootView: nil)
    }
}

public extension BridgingCollectionReusableView {
    func set(rootView: Content, parentViewController: UIViewController) {
        hostingController = RestrictedUIHostingController(rootView: rootView)
        hostingController.view.invalidateIntrinsicContentSize()

        let shouldMoveParentViewController = hostingController.parent != parentViewController
        if shouldMoveParentViewController {
            parentViewController.addChild(hostingController)
        }

        if hostingController.view.superview == nil {
            addSubview(hostingController.view)
            hostingController.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        if shouldMoveParentViewController {
            hostingController.didMove(toParent: parentViewController)
        }

        clearBackgroundColors()
    }

    func setMenuSection(rootView: Content, parentViewController: UIViewController) {
        hostingController = RestrictedUIHostingController(rootView: rootView)
        hostingController.view.invalidateIntrinsicContentSize()

        let shouldMoveParentViewController = hostingController.parent != parentViewController
        if shouldMoveParentViewController {
            parentViewController.addChild(hostingController)
        }

        if hostingController.view.superview == nil {
            addSubview(hostingController.view)
            hostingController.view.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.equalToSuperview()
            }
        }

        if shouldMoveParentViewController {
            hostingController.didMove(toParent: parentViewController)
        }

        clearBackgroundColors()
    }


    func clearBackgroundColors() {
        backgroundColor = .clear
        hostingController.view.backgroundColor = .clear
    }
}

final public class RestrictedUIHostingController<Content>: UIHostingController<Content> where Content: View {

    /// The hosting controller may in some cases want to make the navigation bar be not hidden.
    /// Restrict the access to the outside world, by setting the navigation controller to nil when internally accessed.
    public override var navigationController: UINavigationController? {
        nil
    }
}

public protocol InlineConfigurable {}

extension NSObject: InlineConfigurable {}

public extension InlineConfigurable {
    @discardableResult
    func apply(_ configurator: (Self) -> Void) -> Self {
        configurator(self)
        return self
    }
}

extension UIViewController {
    public class var identifier: String {
        String(describing: self)
    }

    public func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }

    func addBridgedView(_ bridgedView: BridgedView) {
        addChild(bridgedView)
        view.addSubview(bridgedView.view)
        bridgedView.didMove(toParent: self)
    }

    public func add(_ child: UIViewController, to view: UIView, stickingToEdges: Bool = true) {
        addChild(child)
        if stickingToEdges {
            view.addSubviewStickingToEdges(child.view)
        } else {
            view.addSubview(child.view)
        }
        child.didMove(toParent: self)
    }

    func addIgnoringSafeArea(_ bridgedView: BridgedView) {
        add(bridgedView)
        bridgedView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bridgedView.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            bridgedView.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            bridgedView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            bridgedView.view.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        ])
    }

    func addIgnoringSafeArea(_ bridgedView: BridgedView, to view: UIView) {
        addChild(bridgedView)
        view.addSubview(bridgedView.view)
        bridgedView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bridgedView.view.topAnchor.constraint(equalTo: view.topAnchor),
            bridgedView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bridgedView.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            bridgedView.view.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }

    func addBridgedViewAsRoot(_ bridgedView: BridgedView, topToSafeAreaLayoutGuide: Bool = true) {
        add(bridgedView)
        bridgedView.view.translatesAutoresizingMaskIntoConstraints = false
        let topAnchor = topToSafeAreaLayoutGuide ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor
        NSLayoutConstraint.activate([
            bridgedView.view.topAnchor.constraint(equalTo: topAnchor),
            bridgedView.view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            bridgedView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            bridgedView.view.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        ])
    }

    public func remove(childController: UIViewController) {
        childController.willMove(toParent: nil)
        childController.view.removeFromSuperview()
        childController.removeFromParent()
    }

    public func remove() {
        guard parent != nil else {
            return
        }

        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}

extension Publisher {
    public func receiveOnMainQueue() -> Publishers.ReceiveOn<Self, DispatchQueue> {
        receive(on: DispatchQueue.main)
    }
}

extension Optional {
    public var exists: Bool {
        if case .some = self {
            return true
        }
        return false
    }
}

extension UIView {
    func addSubviewStickingToEdges(_ view: UIView, with insets: UIEdgeInsets = .zero) {
        addSubview(view)
        view.pinToSuperview(insets: insets)
    }

    func pinToSuperview(insets: UIEdgeInsets = .zero) {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -insets.right)
        ])
    }
}

extension UIViewController {
    func bindLoading(to view: UIView, from loadingObservable: LoadingObservable) -> AnyCancellable {
        loadingObservable.loadingViewModel
            .$isLoading
            .receiveOnMainQueue()
            .removeDuplicates()
            .sink { isLoading in
                view.isLoading(isLoading)
            }
    }

    func bindLoading(to view: UIView, from loadingViewModel: LoadingViewModel) -> AnyCancellable {
        view.withLoading()

        return loadingViewModel
            .$isLoading
            .receiveOnMainQueue()
            .removeDuplicates()
            .sink { isLoading in
                view.isLoading(isLoading)
            }
    }
}

extension UIView {
    @discardableResult
    func withLoading() -> UIKitLoadingView {
        let loadingView = UIKitLoadingView()
        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.center.equalToSuperview()
        }
        return loadingView
    }

    func isLoading(_ isLoading: Bool) {
        var loadingView = subviews.compactMap { $0 as? UIKitLoadingView }.first
        if loadingView == nil {
            loadingView = self.withLoading()
        }
        if isLoading {
            self.bringSubviewToFront(loadingView!)
            loadingView?.play()
        } else {
            loadingView?.stop()
        }
    }
}

final class UIKitLoadingView: UIView {
    private let artificialDebouncingPeriod: TimeInterval = 0
    private var inProgress = false

    private lazy var loadingView = UIActivityIndicatorView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        alpha = 0
        configureConstraints()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func play() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1
        }
        loadingView.startAnimating()
    }

    func stop() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = 0
        } completion: { _ in
            self.loadingView.stopAnimating()
        }
    }

    func configureConstraints() {
        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.size.equalTo(150)
            make.center.equalToSuperview()
        }
    }
}

struct LoadingView: View {
    enum Constants {
        static let size: CGFloat = 150
    }

    var hasBackground = true

    var body: some View {
        ZStack {
            if hasBackground {
                Color.white
                    .edgesIgnoringSafeArea(.all)
            }
            Circle()
                .frame(width: Constants.size,
                       height: Constants.size)
        }
    }
}

extension View {
    func bindLoading(from loadingViewModel: LoadingViewModel) -> some View {
        environmentObject(loadingViewModel)
    }

    func bindLoading(from loadingObservable: LoadingObservable) -> some View {
        environmentObject(loadingObservable.loadingViewModel)
    }
}

