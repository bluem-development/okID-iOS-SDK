import UIKit

private let logger = Logger.profile

/// Preview screen for captured liveness/selfie data — thin coordinator following MVC pattern
/// - Uses LivenessPreviewContentView for all UI
/// - Controller coordinates image loading, analysis, and callbacks
public class LivenessPreviewViewController: UIViewController {
    
    // MARK: - Properties
    
    private let livenessData: OkIDProfileLivenessData
    private let primaryColor: UIColor
    private let onRecapture: () -> Void
    private let onClose: () -> Void
    
    // Analysis results
    private var faceDetected = false
    private var estimatedAge: Double?
    private var estimatedGender: String?
    private var genderConfidence: Double?
    private var imageSize: CGSize?
    
    // Services
    private let faceDetectionService = FaceDetectionService.shared
    private var ageGenderEstimator: AgeGenderEstimator?
    
    // MARK: - MVC Components
    
    private var contentView: LivenessPreviewContentView!
    
    // MARK: - Initialization
    
    public init(
        livenessData: OkIDProfileLivenessData,
        primaryColor: UIColor,
        onRecapture: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.livenessData = livenessData
        self.primaryColor = primaryColor
        self.onRecapture = onRecapture
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        contentView?.selfieImageView.image = nil
        ageGenderEstimator?.dispose()
        ageGenderEstimator = nil
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImage()
        analyzeImage()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Navigation bar
        title = "Selfie"
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationItem.leftBarButtonItem = OkIDBarButtonItem.close(
            target: self,
            action: #selector(closeTapped)
        )
        
        // Content view
        contentView = LivenessPreviewContentView(
            primaryColor: primaryColor,
            timestampText: formatDate(livenessData.capturedAt)
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
        
        contentView.onRetake = { [weak self] in
            self?.onRecapture()
        }
    }
    
    // MARK: - Image Loading
    
    private func loadImage() {
        imageSize = livenessData.selfieImage.imagePixelSize()
        contentView.selfieImageView.image = livenessData.selfieImage.downsampledUIImage(maxPixelSize: 1536)
    }
    
    // MARK: - Image Analysis
    
    private func analyzeImage() {
        Task {
            do {
                guard let image = livenessData.selfieImage.downsampledUIImage(maxPixelSize: 640) else {
                    await finishAnalysis()
                    return
                }
                
                ageGenderEstimator = AgeGenderEstimator()
                await ageGenderEstimator?.initialize()
                
                let faces = try? await faceDetectionService.detectFaces(in: image)
                faceDetected = !(faces?.isEmpty ?? true)
                
                if let estimatedAge = livenessData.estimatedAge,
                   let estimatedGender = livenessData.estimatedGender {
                    // Reuse the capture-time reading so the preview matches the live liveness overlay.
                    self.estimatedAge = estimatedAge
                    self.estimatedGender = estimatedGender
                    self.genderConfidence = livenessData.genderConfidence
                } else if faceDetected {
                    let faceImage = faces?.first.flatMap { image.croppedFace(to: $0.boundingBox) } ?? image
                    if let result = try? await ageGenderEstimator?.estimate(faceImage: faceImage) {
                        estimatedAge = result.age
                        estimatedGender = result.gender
                        genderConfidence = result.genderConfidence
                    }
                }
                
                await finishAnalysis()
            } catch {
                let okidError = OkIDErrorHandler.shared.normalize(error)
                OkIDErrorHandler.shared.handle(
                    error,
                    context: "LivenessPreviewViewController.analyzeImage",
                    severity: .error
                )
                logger.error("Failed to analyze selfie: \(okidError.errorDescription ?? error.localizedDescription)")
                await finishAnalysis()
            }
        }
    }
    
    @MainActor
    private func finishAnalysis() {
        var metrics: [UIView] = []
        
        // Face detection status
        let faceColor: UIColor = faceDetected ? .okidSuccess : .okidError
        let faceIcon = faceDetected ? "checkmark.circle" : "exclamationmark.circle"
        let faceValue = faceDetected ? "Detected" : "Not detected"
        
        metrics.append(LivenessPreviewContentView.createMetricRow(
            icon: faceIcon,
            iconColor: faceColor,
            label: "Face Detection",
            value: faceValue,
            valueColor: faceColor
        ))
        
        // Estimated age
        if let age = estimatedAge {
            metrics.append(LivenessPreviewContentView.createMetricRow(
                icon: "gift", iconColor: .gray,
                label: "Estimated Age", value: "~\(Int(age)) years"
            ))
        }
        
        // Estimated gender
        if let gender = estimatedGender {
            var genderText = formatGender(gender)
            if let confidence = genderConfidence {
                genderText += " (\(Int(confidence * 100))%)"
            }
            metrics.append(LivenessPreviewContentView.createMetricRow(
                icon: "person", iconColor: .gray,
                label: "Estimated Gender", value: genderText
            ))
        }
        
        // Resolution
        if let size = imageSize {
            metrics.append(LivenessPreviewContentView.createMetricRow(
                icon: "photo", iconColor: .gray,
                label: "Resolution", value: "\(Int(size.width))×\(Int(size.height))px"
            ))
        }
        
        contentView.showMetrics(metrics)
    }
    
    // MARK: - Formatting
    
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' HH:mm"
        return "Captured \(formatter.string(from: date))"
    }
    
    private func formatGender(_ gender: String) -> String {
        switch gender.lowercased() {
        case "male": return "Male"
        case "female": return "Female"
        default: return gender.capitalized
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        onClose()
    }
}

// MARK: - UIScrollViewDelegate

extension LivenessPreviewViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView.imageContainerView
    }
}
