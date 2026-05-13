import UIKit
import AVFoundation

/// QR code scanner module - Controller
/// Thin coordinator between QRScannerManager (business logic),
/// QRScannerState (state), and QRScannerOverlayView (UI)
@MainActor
public class QRScannerViewController: UIViewController {
    
    // MARK: - MVC Components
    
    private let scannerManager: QRScannerManager
    private let scannerState: QRScannerState
    private let overlayView: QRScannerOverlayView
    
    // MARK: - Properties
    
    private let primaryColor: UIColor
    private let onScanComplete: (OkIDQRScanResult?) -> Void
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - Initialization
    
    public init(
        primaryColor: UIColor,
        allowedOrigins: [String]? = nil,
        onScanComplete: @escaping (OkIDQRScanResult?) -> Void
    ) {
        self.primaryColor = primaryColor
        self.onScanComplete = onScanComplete
        
        // Create MVC components
        self.scannerManager = QRScannerManager(allowedOrigins: allowedOrigins)
        self.scannerState = QRScannerState()
        self.overlayView = QRScannerOverlayView(primaryColor: primaryColor)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Scan QR Code"
        view.backgroundColor = .black
        
        setupCamera()
        setupOverlayView()
        setupNavigationItems()
        bindState()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
        scannerManager.startScanning()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scannerManager.stopScanning()
        
        if scannerState.isTorchOn {
            scannerManager.turnOffTorch()
            scannerState.isTorchOn = false
        }
    }
    
    deinit {
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        scannerManager.cleanup()
    }
    
    // MARK: - Setup
    
    private func setupCamera() {
        guard let session = scannerManager.setupCaptureSession(metadataDelegate: self) else {
            scannerState.setFailed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
        
        scannerManager.startScanning()
    }
    
    private func setupOverlayView() {
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func setupNavigationItems() {
        navigationItem.leftBarButtonItem = OkIDBarButtonItem.close(
            target: self,
            action: #selector(closeTapped)
        )
        
        navigationItem.rightBarButtonItem = OkIDBarButtonItem.torch(
            target: self,
            action: #selector(toggleTorch),
            isOn: false
        )
    }
    
    private func bindState() {
        scannerState.onStateChanged = { [weak self] state in
            guard let self else { return }
            switch state {
            case .scanning:
                scannerManager.startScanning()
                
            case .found(let result):
                onScanComplete(result)
                
            case .error(let message):
                showInvalidQRError(message: message)
                
            case .failed:
                showScanningNotSupported()
            }
        }
        
        scannerState.onTorchChanged = { [weak self] isOn in
            guard let self else { return }
            navigationItem.rightBarButtonItem = OkIDBarButtonItem.torch(
                target: self,
                action: #selector(toggleTorch),
                isOn: isOn
            )
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        onScanComplete(nil)
    }
    
    @objc private func toggleTorch() {
        let newState = !scannerState.isTorchOn
        let success = scannerManager.setTorch(on: newState)
        if success == newState {
            scannerState.isTorchOn = newState
        }
    }
    
    // MARK: - Error Presentation
    
    private func showInvalidQRError(message: String) {
        OkIDAlert.show(
            title: "Invalid QR Code",
            message: message,
            actions: [
                .tryAgain { [weak self] in
                    self?.scannerState.resumeScanning()
                },
                .cancel { [weak self] in
                    self?.onScanComplete(nil)
                }
            ],
            from: self
        )
    }
    
    private func showScanningNotSupported() {
        OkIDAlert.showError(
            title: "Scanning not supported",
            message: "Your device does not support scanning QR codes",
            from: self
        ) { [weak self] in
            self?.onScanComplete(nil)
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // Stop scanning and parse via manager
            scannerManager.stopScanning()
            
            let parsed = scannerManager.parseQRCode(stringValue)
            if let scanResult = parsed.result {
                scannerState.codeFound(scanResult)
            } else {
                scannerState.setError(parsed.errorMessage ?? "Invalid QR code")
            }
        }
    }
}
