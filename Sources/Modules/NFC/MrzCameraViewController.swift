//
//  MrzCameraViewController.swift
//  OkIDVerificationSDK
//
//  MRZ camera screen for scanning passport MRZ with live OCR
//  MVC-compliant thin controller:
//    Model:  NFCManager (parsing/logic), MrzTracker (cross-frame confidence)
//    View:   MrzCameraOverlayView (all overlay UI + FieldIndicatorView)
//    State:  MrzCameraState
//  Camera session management remains in controller (lifecycle-coupled).

import UIKit
import AVFoundation
import Vision

private let logger = Logger.mrz

/// MRZ camera screen for scanning passport MRZ with live OCR
/// Thin controller — delegates UI to MrzCameraOverlayView, parsing to NFCManager,
/// tracking to MrzTracker, and state to MrzCameraState.
class MrzCameraViewController: UIViewController {
    
    // MARK: - MVC Components
    
    private let nfcManager = NFCManager()
    private let mrzTracker = MrzTracker()
    private let cameraState = MrzCameraState()
    private let overlayView: MrzCameraOverlayView
    
    // MARK: - Properties
    
    private let primaryColor: UIColor
    private let onDetected: (OkIDPassportCredentials) -> Void
    private let onCancel: () -> Void
    
    // Camera
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var videoOutput: AVCaptureVideoDataOutput?
    
    // OCR
    private let textRecognitionRequest = VNRecognizeTextRequest()
    
    // MARK: - Initialization
    
    init(
        primaryColor: UIColor,
        onDetected: @escaping (OkIDPassportCredentials) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.primaryColor = primaryColor
        self.onDetected = onDetected
        self.onCancel = onCancel
        self.overlayView = MrzCameraOverlayView(primaryColor: primaryColor)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        setupOCR()
        setupCamera()
        setupOverlayView()
        bindCallbacks()
        bindState()
        refreshOverlay()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    deinit {
        captureSession?.stopRunning()
        videoOutput?.setSampleBufferDelegate(nil, queue: nil)
        videoPreviewLayer?.removeFromSuperlayer()
        captureSession = nil
        videoOutput = nil
        videoPreviewLayer = nil
    }
    
    // MARK: - Setup
    
    private func setupOCR() {
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = false
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            showError("Camera not available")
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        output.alwaysDiscardsLateVideoFrames = true
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        videoOutput = output
        captureSession = session
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        videoPreviewLayer = previewLayer
    }
    
    private func setupOverlayView() {
        view.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    // MARK: - Binding
    
    private func bindCallbacks() {
        overlayView.onCloseTapped = { [weak self] in
            self?.closeTapped()
        }
    }
    
    private func bindState() {
        cameraState.onStatusChanged = { [weak self] message in
            self?.overlayView.setStatusMessage(message)
        }
        cameraState.onSpinnerChanged = { [weak self] show in
            DispatchQueue.main.async {
                self?.overlayView.setProcessing(show)
            }
        }
    }
    
    // MARK: - Overlay Refresh
    
    /// Refresh the overlay with current tracker status
    private func refreshOverlay() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Build status message via manager
            let message = self.nfcManager.buildMrzStatusMessage(tracker: self.mrzTracker)
            self.cameraState.statusMessage = message
            
            // Update field indicators
            self.overlayView.updateFieldStatuses(
                docNumber: self.mrzTracker.documentNumberStatus,
                dateOfBirth: self.mrzTracker.dateOfBirthStatus,
                dateOfExpiry: self.mrzTracker.dateOfExpiryStatus
            )
            
            // Update guide color
            self.overlayView.updateGuideColor(allValidated: self.mrzTracker.allFieldsValidated)
        }
    }
    
    // MARK: - Actions
    
    private func closeTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onCancel()
        }
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            OkIDAlert.showError(message: message, from: self) {
                self.dismiss(animated: true) {
                    self.onCancel()
                }
            }
        }
    }
    
    // MARK: - MRZ Processing
    
    private func handleRecognizedText(_ recognizedText: [String]) {
        guard !cameraState.hasCompleted else { return }
        
        let allValidated = nfcManager.processRecognizedText(recognizedText, tracker: mrzTracker)
        
        logger.debug("Tracker counts: \(mrzTracker.detectionCounts)")
        
        refreshOverlay()
        
        if allValidated && !cameraState.hasCompleted {
            cameraState.showSpinner = true
            cameraState.markCompleted()
            completeWithValidatedCredentials()
        }
    }
    
    private func completeWithValidatedCredentials() {
        guard let credentials = nfcManager.buildCredentialsFromTracker(mrzTracker) else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true) {
                self.onDetected(credentials)
            }
        }
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = view.bounds
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension MrzCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !cameraState.isProcessing, !cameraState.hasCompleted else { return }
        
        cameraState.isProcessing = true
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            cameraState.isProcessing = false
            return
        }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try requestHandler.perform([textRecognitionRequest])
            
            if let results = textRecognitionRequest.results {
                let recognizedStrings = results.compactMap { $0.topCandidates(1).first?.string }
                handleRecognizedText(recognizedStrings)
            }
        } catch {
            let okidError = OkIDErrorHandler.shared.normalize(error)
            OkIDErrorHandler.shared.handle(
                error,
                context: "MrzCameraViewController.performOCR",
                severity: .error
            )
            logger.error("OCR error: \(okidError.errorDescription ?? error.localizedDescription)")
        }
        
        // Throttle processing (5 FPS = 200ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.cameraState.isProcessing = false
        }
    }
}
