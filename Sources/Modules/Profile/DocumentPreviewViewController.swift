import UIKit

/// Preview screen for captured document data — thin coordinator following MVC pattern
/// - Uses DocumentPreviewContentView for all UI
/// - Controller coordinates image loading, analysis, and callbacks
public class DocumentPreviewViewController: UIViewController {
    
    // MARK: - Properties
    
    private let documentData: OkIDProfileDocumentData
    private let primaryColor: UIColor
    private let onRecapture: () -> Void
    private let onClose: () -> Void
    
    // Quality metrics
    private var frontBlurScore: Double?
    private var backBlurScore: Double?
    private var showingFront = true
    
    private static let qualityThreshold: Double = 6.0
    
    // MARK: - MVC Components
    
    private var contentView: DocumentPreviewContentView!
    
    // MARK: - Initialization
    
    public init(
        documentData: OkIDProfileDocumentData,
        primaryColor: UIColor,
        onRecapture: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.documentData = documentData
        self.primaryColor = primaryColor
        self.onRecapture = onRecapture
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        contentView?.frontImageView.image = nil
        contentView?.backImageView.image = nil
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImages()
        analyzeImages()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Navigation bar
        title = "ID Document"
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationItem.leftBarButtonItem = OkIDBarButtonItem.close(
            target: self,
            action: #selector(closeTapped)
        )
        
        // Content view
        contentView = DocumentPreviewContentView(
            hasBackImage: documentData.backImage != nil,
            primaryColor: primaryColor,
            timestampText: formatDate(documentData.capturedAt)
        )
        contentView.scrollView.delegate = self
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Bind callbacks
        contentView.onRecapture = { [weak self] in
            self?.onRecapture()
        }
        
        contentView.onToggleSide = { [weak self] index in
            guard let self = self else { return }
            self.showingFront = (index == 0)
            self.updateQualityBadges()
        }
    }
    
    // MARK: - Image Loading
    
    private func loadImages() {
        contentView.frontImageView.image = documentData.frontImage.downsampledUIImage(maxPixelSize: 2048)
        
        if let backData = documentData.backImage {
            contentView.backImageView.image = backData.downsampledUIImage(maxPixelSize: 2048)
        }
    }
    
    // MARK: - Image Analysis
    
    private func analyzeImages() {
        Task {
            if let frontImage = documentData.frontImage.downsampledUIImage(maxPixelSize: 1024) {
                frontBlurScore = BlurDetection.calculateBlurScore(image: frontImage)
            }
            
            if let backData = documentData.backImage {
                if let backImage = backData.downsampledUIImage(maxPixelSize: 1024) {
                    backBlurScore = BlurDetection.calculateBlurScore(image: backImage)
                }
            }
            
            await MainActor.run {
                updateQualityBadges()
            }
        }
    }
    
    private func updateQualityBadges() {
        let score = showingFront ? frontBlurScore : backBlurScore
        let label = showingFront ? "Front" : "Back"
        let image = showingFront ? contentView.frontImageView.image : contentView.backImageView.image
        
        var badges: [UIView] = []
        
        if let score = score {
            badges.append(DocumentPreviewContentView.createQualityBadge(
                score: score,
                label: label,
                qualityThreshold: Self.qualityThreshold
            ))
        }
        
        if let size = image?.size, size.width > 0 {
            badges.append(DocumentPreviewContentView.createResolutionBadge(size: size))
        }
        
        contentView.showQualityBadges(badges)
    }
    
    // MARK: - Formatting
    
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' HH:mm"
        return "Captured \(formatter.string(from: date))"
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        onClose()
    }
}

// MARK: - UIScrollViewDelegate

extension DocumentPreviewViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView.imageContainerView
    }
}
