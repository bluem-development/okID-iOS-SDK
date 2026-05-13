import UIKit

/// Prompt screen for capturing back side of document — thin coordinator following MVC pattern
/// - Uses BackSidePromptContentView for all UI
/// - Controller handles navigation and callback routing
public class BackSidePromptViewController: UIViewController {
    
    private let primaryColor: UIColor
    private let onCaptureBack: () -> Void
    private let onSkipBack: () -> Void
    private let onClose: () -> Void
    
    // MARK: - Initialization
    
    public init(
        primaryColor: UIColor,
        onCaptureBack: @escaping () -> Void,
        onSkipBack: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.primaryColor = primaryColor
        self.onCaptureBack = onCaptureBack
        self.onSkipBack = onSkipBack
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        // Navigation bar
        title = "Document Capture"
        navigationItem.leftBarButtonItem = OkIDBarButtonItem.close(
            target: self,
            action: #selector(closeTapped)
        )
        
        setupUI()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        let contentView = BackSidePromptContentView(primaryColor: primaryColor)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        contentView.onCaptureBack = { [weak self] in
            self?.onCaptureBack()
        }
        
        contentView.onSkipBack = { [weak self] in
            self?.onSkipBack()
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        onClose()
    }
}
