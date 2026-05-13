import UIKit
import AVFoundation
import Vision

private let logger = Logger.liveness

/// Liveness camera screen for selfie capture with face detection
/// MVC-compliant thin controller:
///   Model:  LivenessCameraManager (face detection, state machine, countdown, biometrics)
///   View:   LivenessCameraOverlayView (all overlay UI)
///   State:  LivenessCameraState (CaptureState, flags, biometric data)
/// Camera session management remains in controller (lifecycle-coupled).
public class LivenessCameraScreen: UIViewController {
    
    // MARK: - MVC Components
    
    private let cameraState = LivenessCameraState()
    private let cameraManager: LivenessCameraManager
    private let overlayView = LivenessCameraOverlayView()
    
    // MARK: - Callbacks
    
    private let onImageCaptured: (Data, [String: Any]?) -> Void
    private let onCancel: (() -> Void)?
    
    // MARK: - Permission
    
    private var hasShownPermissionAlert = false
    
    // MARK: - Camera
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureVideoDataOutput?
    
    // MARK: - Initialization
    
    public init(
        onImageCaptured: @escaping (Data, [String: Any]?) -> Void,
        onCancel: (() -> Void)?
    ) {
        self.onImageCaptured = onImageCaptured
        self.onCancel = onCancel
        self.cameraManager = LivenessCameraManager(state: cameraState)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupOverlayView()
        bindState()
        bindCallbacks()
        
        Task {
            await cameraManager.initializeFaceDetector()
        }
        
        cameraManager.startTimers()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAndRequestCameraPermission()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        overlayView.updateOvalCutout(
            in: view.bounds,
            overlayColor: cameraState.overlayColor,
            above: previewLayer
        )
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dispose()
    }

    deinit {
        dispose()
    }
    
    // MARK: - Setup
    
    private func setupOverlayView() {
        view.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    // MARK: - State Binding
    
    private func bindState() {
        // Full UI refresh when state machine or status changes
        cameraState.onUIUpdateNeeded = { [weak self] in
            self?.refreshUI()
        }
        
        // Countdown number changed
        cameraState.onCountdownChanged = { [weak self] remaining in
            DispatchQueue.main.async {
                self?.overlayView.updateCountdown(remaining: remaining)
            }
        }
        
        // Show/hide countdown
        cameraState.onCountdownVisibilityChanged = { [weak self] visible in
            DispatchQueue.main.async {
                self?.overlayView.setCountdownVisible(visible)
            }
        }
        
        // Show countdown display at start
        cameraState.onStartCountdownDisplay = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.overlayView.showCountdown(value: self.cameraState.countdownRemaining)
            }
        }
        
        // Biometric display updated
        cameraState.onBiometricDisplayChanged = { [weak self] reading in
            DispatchQueue.main.async {
                self?.overlayView.updateBiometricDisplay(reading: reading)
            }
        }
        
        // Capture triggered by countdown completion
        cameraState.onCaptureTriggered = { [weak self] in
            self?.captureImage()
        }
    }
    
    private func bindCallbacks() {
        overlayView.onCloseTapped = { [weak self] in
            self?.closeTapped()
        }
    }
    
    // MARK: - UI Refresh
    
    private func refreshUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.overlayView.setStatusMessage(self.cameraState.statusMessage)
            self.overlayView.setOvalColor(self.cameraState.overlayColor)
            self.overlayView.updateStateIndicator(
                visible: self.cameraState.shouldShowStateIndicator,
                info: self.cameraState.stateIndicatorInfo
            )
        }
    }
    
    // MARK: - Camera Permission
    
    private func checkAndRequestCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            initializeCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.initializeCamera()
                    } else {
                        self?.showCameraPermissionAlert()
                    }
                }
            }
        case .denied, .restricted:
            // Already shown alert once (user returned from Settings still denied) → close
            if hasShownPermissionAlert {
                onCancel?()
            } else {
                showCameraPermissionAlert()
            }
        @unknown default:
            initializeCamera()
        }
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
            self?.onCancel?()
        })
        present(alert, animated: true)
    }
    
    // MARK: - Camera Setup
    
    private func initializeCamera() {
        guard captureSession == nil else { return }
        if cameraState.isDisposing { return }
        
        captureSession = AVCaptureSession()
        // Keep .high — the bounding box coordinate system depends on matching
        // the pixel buffer resolution to screen dimensions for size checks.
        // Memory is safe now because we pass CVPixelBuffer directly to Vision
        // (no CGImage/UIImage allocation per frame).
        captureSession?.sessionPreset = .high
        
        guard let captureSession = captureSession,
              let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: frontCamera) else {
            cameraState.statusMessage = "Failed to initialize camera"
            overlayView.setStatusMessage(cameraState.statusMessage)
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        // Preview layer
        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.frame = view.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(preview, at: 0)
        previewLayer = preview
        
        // Photo output
        let photo = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photo) {
            captureSession.addOutput(photo)
        }
        photoOutput = photo
        
        // Video output for face detection
        let video = AVCaptureVideoDataOutput()
        video.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        // Drop late frames rather than queuing them — prevents memory buildup
        video.alwaysDiscardsLateVideoFrames = true
        if captureSession.canAddOutput(video) {
            captureSession.addOutput(video)
        }
        videoOutput = video
        
        // Set focus mode
        try? frontCamera.lockForConfiguration()
        if frontCamera.isFocusModeSupported(.continuousAutoFocus) {
            frontCamera.focusMode = .continuousAutoFocus
        }
        frontCamera.unlockForConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            captureSession.startRunning()
            DispatchQueue.main.async { [weak self] in
                self?.cameraState.isInitialized = true
            }
        }
    }
    
    // MARK: - Photo Capture
    
    private func captureImage() {
        guard let photoOutput = photoOutput, !cameraState.isCameraCapturing else { return }
        
        cameraState.isCameraCapturing = true
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - Cleanup
    
    /// Pre-stop the camera session before the view is removed (for smooth transitions)
    func prepareForRemoval() {
        cameraManager.invalidateTimers()
        
        videoOutput?.setSampleBufferDelegate(nil, queue: nil)
        
        let session = captureSession
        DispatchQueue.global(qos: .userInitiated).async {
            session?.stopRunning()
        }
    }
    
    private func dispose() {
        guard !cameraState.isDisposing else { return }
        cameraState.isDisposing = true
        
        cameraManager.dispose()
        disposeCamera()
    }
    
    private func disposeCamera() {
        let session = captureSession
        captureSession = nil
        cameraState.isInitialized = false

        videoOutput?.setSampleBufferDelegate(nil, queue: nil)
        videoOutput = nil
        photoOutput = nil

        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        
        if let session = session {
            DispatchQueue.global(qos: .userInitiated).async {
                if session.isRunning {
                    session.stopRunning()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        prepareForRemoval()
        onCancel?()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension LivenessCameraScreen: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Keep processing during hold-steady/countdown so lastDetectedFace stays fresh
        // for the biometric timer. Only stop while an actual photo capture is in progress.
        guard !cameraState.isProcessingFrame,
              cameraState.captureState != .capturing else {
            return
        }
        
        // CRITICAL MEMORY FIX:
        // 1. Set isProcessingFrame = true BEFORE any work
        // 2. Clear it ONLY after face detection completes (in the DispatchQueue callback)
        // 3. This ensures only ONE frame is being processed at any time
        // 4. Use CVPixelBuffer directly with Vision — NO CGImage/UIImage allocation per frame
        cameraState.isProcessingFrame = true
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            cameraState.isProcessingFrame = false
            return
        }
        
        // Run face detection synchronously on the video queue using the pixel buffer directly.
        // This avoids creating CGImage/UIImage entirely (~10-20 MB per frame saved).
        // VNImageRequestHandler accepts CVPixelBuffer natively.
        //
        // IMPORTANT: Pass pixel buffer dimensions so bounding box and frame size use the
        // same coordinate space. Previously view.bounds was passed, causing a coordinate
        // mismatch that made isCentered/direction logic unreliable.
        let bufferWidth = CVPixelBufferGetWidth(pixelBuffer)
        let bufferHeight = CVPixelBufferGetHeight(pixelBuffer)
        let bufferSize = CGSize(width: bufferWidth, height: bufferHeight)
        
        do {
            let faces = try cameraManager.detectFaces(in: pixelBuffer)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                defer {
                    // Allow next frame only after UI update completes
                    self.cameraState.isProcessingFrame = false
                }
                
                if faces.isEmpty {
                    self.cameraManager.handleNoFaceDetected()
                } else if faces.count > 1 {
                    self.cameraManager.handleMultipleFaces()
                } else {
                    self.cameraManager.handleSingleFaceDetected(faces[0], pixelBuffer: pixelBuffer, pixelBufferSize: bufferSize)
                }
            }
        } catch {
            cameraState.isProcessingFrame = false
            logger.error("Face detection error: \(error)")
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension LivenessCameraScreen: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        cameraState.isCameraCapturing = false
        
        if let error = error {
            logger.error("Capture error: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.cameraManager.handleCaptureFailed()
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            DispatchQueue.main.async { [weak self] in
                self?.cameraManager.handleCaptureFailed()
            }
            return
        }
        
        // Wrap in autoreleasepool — the intermediate UIImage from imageData is large
        autoreleasepool {
            if let image = UIImage(data: imageData),
               let compressedData = image.jpegData(compressionQuality: 0.9) {
                
                let biometricData = cameraManager.aggregateBiometricData()
                onImageCaptured(compressedData, biometricData)
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.cameraManager.handleCaptureFailed()
                }
            }
        }
    }
}
