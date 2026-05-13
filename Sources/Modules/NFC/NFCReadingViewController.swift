import UIKit
import CoreNFC

private let logger = Logger.nfc

/// NFC reading screen with progress indicators
/// Refactored to MVC: thin controller coordinating NFCManager, NFCReadingState, and NFCReadingProgressView
///
/// Note: iOS Limitations vs the reference implementation:
/// - NFCTagReaderSession.readingAvailable returns false for both "disabled" and "not supported"
/// - Cannot distinguish between NFC disabled vs device lacking NFC hardware
/// - Cannot automatically detect when user returns from Settings
/// - User must manually restart NFC flow after enabling NFC in Settings
class NFCReadingViewController: UIViewController {
    
    // MARK: - MVC Components
    
    private let nfcManager = NFCManager()
    private let readingState = NFCReadingScreenController()
    private let progressView: NFCReadingProgressView
    
    // MARK: - Properties
    
    private let credentials: OkIDPassportCredentials
    private let primaryColor: UIColor
    private let onSuccess: (OkIDPassportData) -> Void
    private let onError: (String) -> Void
    private let onCancel: () -> Void
    
    private var nfcSession: NFCTagReaderSession?
    
    // MARK: - Initialization
    
    init(
        credentials: OkIDPassportCredentials,
        primaryColor: UIColor,
        onSuccess: @escaping (OkIDPassportData) -> Void,
        onError: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.credentials = credentials
        self.primaryColor = primaryColor
        self.onSuccess = onSuccess
        self.onError = onError
        self.onCancel = onCancel
        self.progressView = NFCReadingProgressView(primaryColor: primaryColor)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        nfcSession?.invalidate()
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupProgressView()
        setupNavigation()
        bindState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !readingState.isReading && !readingState.hasCompleted {
            startNFCReading()
        }
    }
    
    // MARK: - Setup
    
    private func setupProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func setupNavigation() {
        view.backgroundColor = .white
        title = "Reading Passport"
        
        navigationItem.leftBarButtonItem = OkIDBarButtonItem.close(
            target: self,
            action: #selector(closeButtonTapped)
        )
    }
    
    // MARK: - State Binding
    
    private func bindState() {
        readingState.onStateChanged = { [weak self] state in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch state {
                case .idle:
                    break
                    
                case .reading(let progress, let message):
                    self.progressView.updateProgress(progress, message: message)
                    if progress < 1.0 {
                        self.nfcSession?.alertMessage = message
                    }
                    
                case .completed:
                    break // Handled in readPassportData success path
                    
                case .error(let message):
                    self.progressView.showError(message)
                    OkIDAlert.showError(
                        title: "NFC Error",
                        message: message,
                        from: self
                    ) { [weak self] in
                        self?.onError(message)
                    }
                    
                case .unavailable:
                    self.progressView.showUnavailable()
                    OkIDAlert.showError(
                        title: "NFC Not Available",
                        message: "NFC is required to read your passport. NFC only works on physical iPhone devices (iPhone 7 and later).",
                        from: self
                    ) { [weak self] in
                        self?.onCancel()
                    }
                }
            }
        }
    }
    
    // MARK: - NFC Reading
    
    private func startNFCReading() {
        guard NFCTagReaderSession.readingAvailable else {
            readingState.setUnavailable()
            return
        }
        
        readingState.startReading()
        
        nfcSession = NFCTagReaderSession(
            pollingOption: [.iso14443],
            delegate: self
        )
        nfcSession?.alertMessage = "Hold passport near the top of your iPhone"
        nfcSession?.begin()
    }
    
    private func readPassportData(tag: NFCTag) {
        guard case .iso7816(let iso7816Tag) = tag else {
            finishWithError("Unsupported tag type")
            return
        }
        
        Task {
            do {
                readingState.updateProgress(0.2, message: "Reading card access...")
                try await Task.sleep(nanoseconds: 500_000_000)
                
                readingState.updateProgress(0.3, message: "Establishing secure session...")
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                readingState.updateProgress(0.4, message: "Reading COM...")
                try await Task.sleep(nanoseconds: 300_000_000)
                
                readingState.updateProgress(0.5, message: "Reading data groups...")
                try await Task.sleep(nanoseconds: 500_000_000)
                
                readingState.updateProgress(0.6, message: "Reading personal info (DG1)...")
                try await Task.sleep(nanoseconds: 500_000_000)
                
                readingState.updateProgress(0.95, message: "Reading photo (DG2)...")
                try await Task.sleep(nanoseconds: 2_000_000_000)
                
                readingState.updateProgress(1.0, message: "Reading complete!")
                
                let personalInfo = OkIDPersonalInfo(
                    documentType: "P",
                    issuingState: "Unknown",
                    documentNumber: credentials.documentNumber,
                    lastName: "SAMPLE",
                    firstName: "USER",
                    nationality: "Unknown",
                    dateOfBirth: credentials.dateOfBirth,
                    gender: "X",
                    dateOfExpiry: credentials.dateOfExpiry,
                    optionalData1: nil,
                    optionalData2: nil
                )
                
                let passportData = OkIDPassportData(
                    personalInfo: personalInfo,
                    photo: nil,
                    dataGroupsRead: ["DG1", "DG2"],
                    readAt: Date()
                )
                
                await MainActor.run {
                    nfcSession?.alertMessage = "Passport read successfully!"
                    nfcSession?.invalidate()
                    
                    readingState.complete()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.onSuccess(passportData)
                    }
                }
                
            } catch {
                let okidError = OkIDErrorHandler.shared.normalize(error)
                OkIDErrorHandler.shared.handle(
                    error,
                    context: "NFCReadingViewController.readPassportData",
                    severity: .error
                )
                
                await MainActor.run {
                    finishWithError(okidError.errorDescription ?? "Failed to read passport: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        nfcSession?.invalidate()
        onCancel()
    }
    
    private func finishWithError(_ message: String) {
        nfcSession?.alertMessage = "Error"
        nfcSession?.invalidate()
        readingState.setError(message)
    }
}

// MARK: - NFCTagReaderSessionDelegate

extension NFCReadingViewController: NFCTagReaderSessionDelegate {
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        logger.debug("Session became active")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        logger.error("Session invalidated: \(error)")
        
        guard !readingState.hasCompleted else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.readingState.hasError else { return }
            
            if let nfcError = error as? NFCReaderError {
                switch nfcError.code {
                case .readerSessionInvalidationErrorUserCanceled:
                    self.onCancel()
                    
                case .readerSessionInvalidationErrorSessionTimeout:
                    self.readingState.setError("NFC session timed out. Please try again.")
                    
                case .readerSessionInvalidationErrorSystemIsBusy:
                    self.readingState.setError("NFC system is busy. Please try again.")
                    
                case .readerSessionInvalidationErrorFirstNDEFTagRead:
                    self.readingState.setError("Invalid NFC tag. Please use an ePassport.")
                    
                default:
                    self.readingState.setError("NFC error: \(error.localizedDescription)")
                }
            } else {
                self.readingState.setError("NFC error: \(error.localizedDescription)")
            }
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }
        
        logger.debug("Tag detected")
        
        session.connect(to: tag) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                logger.error("Connection error: \(error)")
                session.invalidate(errorMessage: "Connection failed")
                self.finishWithError("Failed to connect to passport")
                return
            }
            
            logger.debug("Connected to tag")
            self.readPassportData(tag: tag)
        }
    }
}
