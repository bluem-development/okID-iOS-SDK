import UIKit

/// Pure UI view for the NFC reading progress screen
/// Contains: icon, status label, progress bar, and progress percentage label
class NFCReadingProgressView: UIView {
    
    // MARK: - Properties
    
    private let primaryColor: UIColor
    
    // MARK: - UI Elements
    
    let scrollView = OkIDScrollView()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let nfcIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "wave.3.right"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let statusLabel: OkIDLabel = {
        let label = OkIDLabel()
        label.text = "Hold passport near device..."
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()
    
    private let progressLabel: OkIDLabel = {
        let label = OkIDLabel()
        label.text = "0%"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Initialization
    
    init(primaryColor: UIColor) {
        self.primaryColor = primaryColor
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .white
        
        iconContainer.backgroundColor = primaryColor.withAlphaComponent(0.1)
        iconContainer.layer.cornerRadius = 60
        nfcIcon.tintColor = primaryColor
        
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        iconContainer.addSubview(nfcIcon)
        contentView.addSubview(iconContainer)
        contentView.addSubview(statusLabel)
        contentView.addSubview(progressView)
        contentView.addSubview(progressLabel)
        
        progressView.progressTintColor = primaryColor
        progressView.trackTintColor = UIColor(white: 0.9, alpha: 1.0)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            iconContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            iconContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 120),
            iconContainer.heightAnchor.constraint(equalToConstant: 120),
            
            nfcIcon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            nfcIcon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            nfcIcon.widthAnchor.constraint(equalToConstant: 60),
            nfcIcon.heightAnchor.constraint(equalToConstant: 60),
            
            statusLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 24),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            progressView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            
            progressLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 12),
            progressLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            progressLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
        ])
    }
    
    // MARK: - Public Updates
    
    /// Update progress bar and status message
    func updateProgress(_ progress: Float, message: String) {
        UIView.animate(withDuration: 0.3) {
            self.progressView.setProgress(progress, animated: true)
        }
        progressLabel.text = "\(Int(progress * 100))%"
        statusLabel.text = message
        statusLabel.textColor = .darkGray
    }
    
    /// Show error state with red icon and message
    func showError(_ message: String) {
        nfcIcon.image = UIImage(systemName: "exclamationmark.triangle")
        nfcIcon.tintColor = .systemRed
        iconContainer.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        statusLabel.text = message
        statusLabel.textColor = .systemRed
        progressView.isHidden = true
        progressLabel.isHidden = true
    }
    
    /// Show unavailable state
    func showUnavailable() {
        nfcIcon.image = UIImage(systemName: "exclamationmark.triangle")
        nfcIcon.tintColor = .systemRed
        iconContainer.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        statusLabel.text = "NFC is not available"
        statusLabel.textColor = .black
        progressView.isHidden = true
        progressLabel.isHidden = true
    }
}
