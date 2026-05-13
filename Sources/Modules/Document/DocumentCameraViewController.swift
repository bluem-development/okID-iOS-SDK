import UIKit
import AVFoundation
import Vision
import CoreImage
import AudioToolbox

private let logger = Logger.camera

/// Document camera view controller — thin coordinator following MVC pattern
/// - Uses DocumentCameraState for state management
/// - Uses DocumentCameraManager for business logic
/// - Uses DocumentCameraOverlayView for UI
class DocumentCameraViewController: UIViewController {
    
    // MARK: - Properties
    
    private let side: String
    private let qualityThreshold: Double
    private let primaryColor: UIColor
    private let onImageCaptured: (Data, Double) -> Void
    private let onCancel: () -> Void
    
    // MARK: - MVC Components
    
    private let cameraState = DocumentCameraState()
    private let cameraManager: DocumentCameraManager
    private let overlayView: DocumentCameraOverlayView
    
    // MARK: - Camera
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    
    // Permission
    private var hasShownPermissionAlert = false
    
    // Quality check timer
    private var qualityCheckTimer: Timer?
    
    // Store quality check delegate to prevent deallocation
    private var currentQualityDelegate: QualityCheckPhotoDelegate?
    
    // Flash effect
    private var flashView: UIView?
    
    // UI
    private lazy var captureButton: OkIDButton = {
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        let icon = UIImage(systemName: "camera", withConfiguration: iconConfig)
        
        let config = OkIDButtonConfig(
            backgroundColor: .white,
            titleColor: .black,
            cornerRadius: 35,
            borderWidth: 4,
            borderColor: .white,
            hasShadow: false,
            icon: icon,
            iconPlacement: .leading,
            height: 70
        )
        
        let button = OkIDButton(config: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    
    init(
        side: String,
        qualityThreshold: Double,
        primaryColor: UIColor,
        onImageCaptured: @escaping (Data, Double) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.side = side
        self.qualityThreshold = qualityThreshold
        self.primaryColor = primaryColor
        self.onImageCaptured = onImageCaptured
        self.onCancel = onCancel
        self.cameraManager = DocumentCameraManager(qualityThreshold: qualityThreshold)
        self.overlayView = DocumentCameraOverlayView(
            side: side,
            qualityThreshold: qualityThreshold,
            onCancel: onCancel
        )
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        setupUI()
        updateOverlay()
        
        logger.info("Initialized successfully")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAndRequestCameraPermission()
    }
    
    /// Attempt to start the capture session, retrying if the hardware is still
    /// held by a previous VC (common on memory-constrained devices like iPhone 6s).
    private func startCameraSession(attempt: Int) {
        let maxAttempts = 3
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if self.captureSession?.isRunning == true {
                    logger.info("Camera session started (attempt \(attempt))")
                    self.startQualityCheckTimer()
                } else if attempt < maxAttempts {
                    logger.warning("Camera session not running (attempt \(attempt)/\(maxAttempts)), retrying in 0.5s...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        // Re-setup camera on retry in case the session is in a bad state
                        if attempt >= 2 {
                            self?.releaseCamera()
                            self?.setupCamera()
                        }
                        self?.startCameraSession(attempt: attempt + 1)
                    }
                } else {
                    logger.error("Camera session failed to start after \(maxAttempts) attempts")
                    // Start timer anyway so user can still manually capture if session recovers
                    self.startQualityCheckTimer()
                }
            }
        }
    }
    
    private func startQualityCheckTimer() {
        guard qualityCheckTimer == nil else { return }
        qualityCheckTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(DocumentCaptureConfig.qualityCheckIntervalMs) / 1000.0,
            repeats: true
        ) { [weak self] _ in
            self?.checkAutoCaptureConditions()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        qualityCheckTimer?.invalidate()
        qualityCheckTimer = nil
        
        // Stop the session on a background queue (stopRunning is blocking).
        // Capture a strong reference so it stops even if self is deallocated.
        let session = captureSession
        DispatchQueue.global(qos: .userInitiated).async {
            session?.stopRunning()
        }
        
        // Release all camera resources immediately so the next camera VC
        // can acquire the hardware. Setting captureSession = nil doesn't
        // stop the session — the local `session` reference above keeps it
        // alive long enough for stopRunning() to complete.
        releaseCamera()
    }
    
    private func releaseCamera() {
        videoPreviewLayer?.removeFromSuperlayer()
        videoPreviewLayer = nil
        photoOutput = nil
        captureSession = nil
        cameraState.validatedImage = nil
    }
    
    deinit {
        qualityCheckTimer?.invalidate()
        qualityCheckTimer = nil
        captureSession?.stopRunning()
        releaseCamera()
    }
    
    // MARK: - Camera Permission
    
    private func checkAndRequestCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            setupCameraIfNeeded()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCameraIfNeeded()
                    } else {
                        self?.showCameraPermissionAlert()
                    }
                }
            }
        case .denied, .restricted:
            if hasShownPermissionAlert {
                onCancel()
            } else {
                showCameraPermissionAlert()
            }
        @unknown default:
            setupCameraIfNeeded()
        }
    }
    
    private func setupCameraIfNeeded() {
        if captureSession == nil {
            setupCamera()
        }
        startCameraSession(attempt: 1)
    }
    
    private func showCameraPermissionAlert() {
        hasShownPermissionAlert = true
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please allow camera access to continue.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.onCancel()
        })
        present(alert, animated: true)
    }
    
    // MARK: - Setup
    
    private func setupCamera() {
        let session = AVCaptureSession()
        // Use .high instead of .photo to reduce memory pressure on older devices.
        // .high still produces good quality images for document capture while
        // using significantly less RAM (critical for iPhone 6s with 2GB).
        session.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            showError("Camera not available")
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let photoOut = AVCapturePhotoOutput()
        if session.canAddOutput(photoOut) {
            session.addOutput(photoOut)
        }
        photoOutput = photoOut
        
        captureSession = session
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        videoPreviewLayer = previewLayer
    }
    
    private func setupUI() {
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        view.addSubview(captureButton)
        
        // Setup flash view
        flashView = UIView()
        flashView?.backgroundColor = .white
        flashView?.alpha = 0
        flashView?.translatesAutoresizingMaskIntoConstraints = false
        if let flash = flashView {
            view.addSubview(flash)
            NSLayoutConstraint.activate([
                flash.topAnchor.constraint(equalTo: view.topAnchor),
                flash.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                flash.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                flash.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        captureButton.addTarget(self, action: #selector(captureTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
        ])
        
        updateButtonState()
    }
    
    // MARK: - Auto-Capture Check
    
    private func checkAutoCaptureConditions() {
        guard !cameraState.isCapturing && !cameraState.autoCaptureFired && !cameraState.isCheckingQuality else {
            return
        }
        
        guard let photoOutput = photoOutput else { return }
        
        cameraState.isCheckingQuality = true
        
        logger.debug("Starting quality check...")
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        
        currentQualityDelegate = QualityCheckPhotoDelegate { [weak self] imageData in
            guard let self = self else { return }
            
            defer {
                self.cameraState.isCheckingQuality = false
                self.currentQualityDelegate = nil
            }
            
            guard let imageData = imageData else {
                logger.error("Failed to capture quality check image")
                return
            }
            
            self.cameraManager.processQualityCheck(
                imageData: imageData,
                state: self.cameraState
            ) { [weak self] blurScore, detectionState, readyForCapture in
                guard let self = self else { return }
                
                self.updateOverlay()
                self.updateButtonState()
                
                if readyForCapture {
                    self.captureImage(isAutoCapture: true)
                }
            }
        }
        
        guard let delegate = currentQualityDelegate else {
            cameraState.isCheckingQuality = false
            logger.error("ERROR: Quality delegate is nil!")
            return
        }
        
        logger.debug("Capturing quality check photo with delegate: \(delegate)")
        
        cameraManager.silentCapture {
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
    
    // MARK: - UI Updates
    
    private func updateOverlay() {
        let message = cameraManager.getStatusMessage(state: cameraState)
        overlayView.update(
            qualityScore: cameraState.currentBlurScore,
            detectionState: cameraState.detectionState,
            message: message
        )
    }
    
    private func updateButtonState() {
        let isEnabled = cameraManager.isCaptureEnabled(state: cameraState)
        captureButton.isEnabled = isEnabled
        
        let appearance = cameraManager.getCaptureButtonAppearance(state: cameraState)
        captureButton.backgroundColor = appearance.backgroundColor
        captureButton.tintColor = appearance.tintColor
        captureButton.imageView?.alpha = appearance.iconAlpha
    }
    
    // MARK: - Actions
    
    @objc private func captureTapped() {
        guard !cameraState.isCapturing else { return }
        captureImage(isAutoCapture: false)
    }
    
    // MARK: - Capture Image
    
    private func captureImage(isAutoCapture: Bool) {
        guard !cameraState.isCapturing,
              let photoOutput = photoOutput,
              captureSession?.isRunning == true else {
            logger.error("Cannot capture: isCapturing=\(cameraState.isCapturing), session running=\(captureSession?.isRunning ?? false)")
            return
        }
        
        cameraState.isCapturing = true
        
        // Flash effect and haptic for auto-capture
        if isAutoCapture {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showFlashEffect()
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateOverlay()
            self.updateButtonState()
            
            if self.cameraState.isCapturing {
                self.captureButton.isLoading = true
            }
        }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        
        logger.debug("Capturing main photo (isAutoCapture: \(isAutoCapture)) with self as delegate")
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func showFlashEffect() {
        guard let flashView = flashView else { return }
        
        flashView.alpha = 0.6
        UIView.animate(withDuration: 0.2) {
            flashView.alpha = 0
        }
    }
    
    private func showError(_ message: String) {
        OkIDAlert.showError(message: message, from: self) { [weak self] in
            self?.onCancel()
        }
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = view.bounds
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension DocumentCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        logger.error("Main capture delegate called, error: \(error?.localizedDescription ?? "none")")
        
        defer {
            DispatchQueue.main.async { [weak self] in
                self?.cameraState.isCapturing = false
                self?.captureButton.isLoading = false
                self?.updateButtonState()
            }
        }
        
        // Use manager to process the final image
        let finalImage: UIImage
        let blurScore: Double
        
        if cameraState.autoCaptureFired, let validated = cameraState.validatedImage {
            logger.debug("Using pre-validated guide area frame for auto-capture")
            finalImage = validated
            blurScore = cameraState.validatedBlurScore ?? BlurDetection.calculateBlurScore(image: validated)
        } else {
            guard error == nil,
                  let imageData = photo.fileDataRepresentation(),
                  let fullImage = UIImage(data: imageData) else {
                logger.error("Failed to capture image")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.overlayView.update(
                        qualityScore: self.cameraState.currentBlurScore,
                        detectionState: self.cameraState.detectionState,
                        message: "Failed to capture image"
                    )
                }
                return
            }
            
            logger.debug("Captured \(imageData.count) bytes")
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.overlayView.update(
                    qualityScore: self.cameraState.currentBlurScore,
                    detectionState: self.cameraState.detectionState,
                    message: "Processing image quality..."
                )
            }
            
            // Calculate guide rect if needed
            if cameraState.guideRect == nil {
                cameraState.guideRect = cameraManager.calculateGuideRect(imageSize: fullImage.size)
            }
            
            guard let croppedImage = cameraManager.cropImageToGuideArea(image: fullImage, guideRect: cameraState.guideRect!) else {
                logger.error("Failed to crop image to guide area")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.overlayView.update(
                        qualityScore: self.cameraState.currentBlurScore,
                        detectionState: self.cameraState.detectionState,
                        message: "Failed to process image"
                    )
                }
                return
            }
            
            logger.debug("Cropped to guide area: \(Int(croppedImage.size.width))x\(Int(croppedImage.size.height))")
            
            let calculatedBlur = BlurDetection.calculateBlurScore(image: croppedImage)
            logger.debug("Calculated blur score: \(String(format: "%.2f", calculatedBlur))")
            
            // Check quality for manual capture
            if calculatedBlur < qualityThreshold {
                let tip = calculatedBlur < qualityThreshold * 0.5
                    ? "Try better lighting or clean lens"
                    : "Hold phone more steady"
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.overlayView.update(
                        qualityScore: calculatedBlur,
                        detectionState: self.cameraState.detectionState,
                        message: "Image not sharp enough. \(tip)."
                    )
                }
                return
            }
            
            finalImage = croppedImage
            blurScore = calculatedBlur
        }
        
        // Encode cropped image to JPEG
        guard let jpegData = finalImage.jpegData(compressionQuality: 0.95) else {
            showError("Failed to encode image")
            return
        }
        
        logger.debug("Quality check passed: \(String(format: "%.2f", blurScore)) >= \(qualityThreshold)")
        logger.debug("Final JPEG size: \(jpegData.count) bytes")
        
        onImageCaptured(jpegData, blurScore)
    }
}

// MARK: - Quality Check Photo Delegate

private class QualityCheckPhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Data?) -> Void
    
    init(completion: @escaping (Data?) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
        logger.debug("Quality check: Suppressing shutter sound")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        logger.error("Photo capture completed, error: \(error?.localizedDescription ?? "none")")
        
        guard error == nil,
              let imageData = photo.fileDataRepresentation() else {
            logger.error("Failed to get image data")
            completion(nil)
            return
        }
        
        logger.info("Successfully captured image data: \(imageData.count) bytes")
        completion(imageData)
    }
}
