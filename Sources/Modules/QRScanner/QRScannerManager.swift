import Foundation
import AVFoundation

private let logger = Logger.qr

// MARK: - QR Scanner Manager

/// Manages business logic for QR code scanning
/// Extracted from QRScannerViewController following proper MVC pattern
/// Handles: camera session setup, torch control, QR code parsing
class QRScannerManager {
    
    // MARK: - Properties
    
    private let parser: QRURLParser
    private(set) var captureSession: AVCaptureSession?
    
    // MARK: - Initialization
    
    init(allowedOrigins: [String]? = nil) {
        self.parser = QRURLParser(allowedOrigins: allowedOrigins)
    }
    
    // MARK: - Camera Session
    
    /// Create and configure the capture session
    /// Returns the session if successful, nil otherwise
    func setupCaptureSession(metadataDelegate: AVCaptureMetadataOutputObjectsDelegate) -> AVCaptureSession? {
        let session = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            logger.error("No video capture device available")
            return nil
        }
        
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            OkIDErrorHandler.shared.handle(
                OkIDError.cameraInitializationFailed,
                context: "QRScannerManager.setupCaptureSession",
                severity: .error
            )
            return nil
        }
        
        guard session.canAddInput(videoInput) else {
            logger.error("Cannot add video input to session")
            return nil
        }
        session.addInput(videoInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else {
            logger.error("Cannot add metadata output to session")
            return nil
        }
        session.addOutput(metadataOutput)
        
        metadataOutput.setMetadataObjectsDelegate(metadataDelegate, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]
        
        self.captureSession = session
        return session
    }
    
    // MARK: - Session Lifecycle
    
    func startScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if self?.captureSession?.isRunning == false {
                self?.captureSession?.startRunning()
            }
        }
    }
    
    func stopScanning() {
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
    
    /// Clean up session resources
    func cleanup() {
        stopScanning()
        
        if let session = captureSession {
            for output in session.outputs {
                if let metadataOutput = output as? AVCaptureMetadataOutput {
                    metadataOutput.setMetadataObjectsDelegate(nil, queue: nil)
                }
            }
        }
        
        captureSession = nil
    }
    
    // MARK: - Torch Control
    
    /// Toggle torch and return new state (true = on, false = off)
    func setTorch(on: Bool) -> Bool {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            return false
        }
        
        do {
            try device.lockForConfiguration()
            
            if on {
                try device.setTorchModeOn(level: 1.0)
            } else {
                device.torchMode = .off
            }
            
            device.unlockForConfiguration()
            return on
        } catch {
            OkIDErrorHandler.shared.handle(
                error,
                context: "QRScannerManager.setTorch",
                severity: .warning
            )
            logger.error("Torch could not be used: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Turn off torch (convenience for cleanup)
    func turnOffTorch() {
        _ = setTorch(on: false)
    }
    
    // MARK: - QR Code Parsing
    
    /// Parse a scanned QR code string
    /// Returns the scan result on success, or an error message string on failure
    func parseQRCode(_ code: String) -> (result: OkIDQRScanResult?, errorMessage: String?) {
        let parseResult = parser.parse(url: code)
        
        switch parseResult {
        case .success(let parsed):
            let scanResult = OkIDQRScanResult(parseResult: parsed, rawUrl: code)
            logger.debug("QR code parsed successfully: \(scanResult.origin)")
            return (result: scanResult, errorMessage: nil)
            
        case .failure(let error):
            logger.warning("Invalid QR code: \(error.localizedDescription)")
            return (result: nil, errorMessage: error.localizedDescription)
        }
    }
}
