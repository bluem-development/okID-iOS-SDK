import UIKit

/// Profile dashboard module - Controller
/// Thin coordinator between ProfileDashboardManager (business logic),
/// ProfileDashboardState (state), and ProfileDashboardContentView (UI)
@MainActor
public class ProfileDashboardViewController: UIViewController {
    
    // MARK: - MVC Components
    
    private let profileManager: ProfileDashboardManager
    private let profileState: ProfileDashboardState
    private let contentView: ProfileDashboardContentView
    
    // MARK: - Properties
    
    private let config: OkIDSDKConfig
    private let onComplete: (OkIDProfileResult?) -> Void
    
    // Navigation
    private var navigationBar: UINavigationBar!
    private var deleteBarButton: UIBarButtonItem?
    
    // MARK: - Initialization
    
    public init(config: OkIDSDKConfig, onComplete: @escaping (OkIDProfileResult?) -> Void) {
        self.config = config
        self.onComplete = onComplete
        
        // Create MVC components
        self.profileManager = ProfileDashboardManager(config: config)
        self.profileState = ProfileDashboardState()
        self.contentView = ProfileDashboardContentView(
            primaryColor: config.theme.colors.primary
        )
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .okidBackgroundDark
        
        setupNavigationBar()
        setupContentView()
        bindState()
        bindViewCallbacks()
        checkPinAndLoad()
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        navigationBar = UINavigationBar()
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = .okidBackgroundDark
        navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navigationBar.tintColor = .white
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)
        
        let navItem = UINavigationItem(title: "")
        navItem.leftBarButtonItem = OkIDBarButtonItem.close(
            target: self,
            action: #selector(closeTapped)
        )
        
        deleteBarButton = OkIDBarButtonItem.delete(
            target: self,
            action: #selector(deleteProfileTapped)
        )
        deleteBarButton?.tintColor = .red
        
        navigationBar.setItems([navItem], animated: false)
        
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    private func setupContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func bindState() {
        profileState.onStateChanged = { [weak self] state in
            guard let self else { return }
            switch state {
            case .checkingPin, .loading:
                contentView.setLoading(true)
                
            case .pinRequired:
                contentView.setLoading(false)
                showPinVerification()
                
            case .loaded:
                contentView.setLoading(false)
                let hasProfile = profileState.hasProfile
                navigationBar.topItem?.rightBarButtonItem = hasProfile ? deleteBarButton : nil
                rebuildContent()
                
            case .error(let message):
                contentView.setLoading(false)
                contentView.showMessage(message, type: .error)
            }
        }
        
        profileState.onPinStateChanged = { [weak self] _ in
            guard let self else { return }
            rebuildContent()
        }
    }
    
    private func bindViewCallbacks() {
        contentView.onModuleCardTapped = { [weak self] moduleKey in
            switch moduleKey {
            case "document": self?.captureDocument()
            case "liveness": self?.captureLiveness()
            case "nfc":      self?.captureNfc()
            default: break
            }
        }
        
        contentView.onSecurityToggleTapped = { [weak self] in
            self?.handleSecurityToggle()
        }
    }
    
    // MARK: - Display Data Preparation
    
    /// Rebuild content by preparing display data from the manager and passing to the view
    private func rebuildContent() {
        let displayData = buildDisplayData()
        contentView.buildContent(data: displayData)
    }
    
    /// Controller responsibility: transform business data into display data
    /// This keeps the View free from any Manager knowledge
    private func buildDisplayData() -> ProfileDashboardDisplayData {
        let status = profileState.profileStatus
        let primaryColor = config.theme.colors.primary
        
        // Title
        let titleData = ProfileTitleSectionData(primaryColor: primaryColor)
        
        // Progress
        let level = profileManager.calculateSecurityLevel(from: status)
        let (title, description, color) = profileManager.getSecurityLevelInfo(level: level)
        
        var segmentColors: [UIColor] = []
        for segment in 1...3 {
            if level >= segment {
                if segment == 1 && level == 1 {
                    segmentColors.append(profileManager.colorOutdated)
                } else {
                    segmentColors.append(primaryColor)
                }
            } else {
                segmentColors.append(UIColor.white.withAlphaComponent(0.1))
            }
        }
        
        let progressData = ProfileProgressData(
            level: level,
            title: title,
            description: description,
            color: color,
            segmentColors: segmentColors
        )
        
        // Module cards
        let moduleCards = [
            buildModuleCardData(
                moduleKey: "document",
                icon: "doc.text",
                title: "ID Document",
                status: status.document,
                capturedAt: status.documentCapturedAt,
                tierHint: "Level 1 • Required for verification",
                isOptional: false,
                primaryColor: primaryColor
            ),
            buildModuleCardData(
                moduleKey: "liveness",
                icon: "face.smiling",
                title: "Selfie",
                status: status.liveness,
                capturedAt: status.livenessCapturedAt,
                tierHint: "Level 2 • Adds biometric verification",
                isOptional: false,
                primaryColor: primaryColor
            ),
            buildModuleCardData(
                moduleKey: "nfc",
                icon: "wave.3.right",
                title: "Passport Chip",
                status: status.nfc,
                capturedAt: status.nfcCapturedAt,
                tierHint: "Level 3 • For passports only",
                isOptional: true,
                primaryColor: primaryColor
            )
        ]
        
        // Security toggle
        let securityToggle = ProfileSecurityToggleData(
            isPinEnabled: profileState.isPinEnabled,
            primaryColor: primaryColor
        )
        
        return ProfileDashboardDisplayData(
            titleData: titleData,
            progressData: progressData,
            moduleCards: moduleCards,
            securityToggle: securityToggle
        )
    }
    
    private func buildModuleCardData(
        moduleKey: String,
        icon: String,
        title: String,
        status: OkIDProfileModuleStatus,
        capturedAt: Int64?,
        tierHint: String?,
        isOptional: Bool,
        primaryColor: UIColor
    ) -> ProfileModuleCardData {
        let isCaptured = status != .none
        let statusColor = profileManager.getStatusColor(status)
        let statusText = profileManager.getStatusText(status, capturedAt: capturedAt)
        
        let badgeIcon: String?
        if isCaptured {
            badgeIcon = status == .fresh ? "checkmark" : "clock"
        } else {
            badgeIcon = nil
        }
        
        return ProfileModuleCardData(
            moduleKey: moduleKey,
            icon: icon,
            title: title,
            isCaptured: isCaptured,
            isOptional: isOptional,
            statusColor: statusColor,
            statusText: statusText,
            tierHint: tierHint,
            statusBadgeIcon: badgeIcon,
            primaryColor: primaryColor
        )
    }
    
    // MARK: - PIN & Data Loading
    
    private func checkPinAndLoad() {
        Task {
            let pinEnabled = await profileManager.checkPinEnabled()
            profileState.isPinEnabled = pinEnabled
            profileState.isPinVerified = !pinEnabled
            
            if profileState.isPinVerified {
                await loadStatus()
            } else {
                profileState.requirePin()
            }
        }
    }
    
    private func loadStatus() async {
        profileState.startLoading()
        let status = await profileManager.loadProfileStatus()
        profileState.finishLoading(status: status)
    }
    
    private func showPinVerification() {
        let pinVC = PinViewController(
            flowType: .verify,
            primaryColor: config.theme.colors.primary
        ) { [weak self] success in
            if success {
                self?.profileState.pinVerified()
                self?.dismiss(animated: true) {
                    Task {
                        await self?.loadStatus()
                    }
                }
            } else {
                self?.dismiss(animated: true) {
                    self?.onComplete(OkIDProfileResult.cancelled())
                }
            }
        }
        
        let nav = UINavigationController(rootViewController: pinVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    // MARK: - Capture Actions
    
    private func captureDocument() {
        if profileState.profileStatus.document != .none {
            showModulePreview(module: "document")
        } else {
            doDocumentCapture()
        }
    }
    
    private func captureLiveness() {
        if profileState.profileStatus.liveness != .none {
            showModulePreview(module: "liveness")
        } else {
            doLivenessCapture()
        }
    }
    
    private func captureNfc() {
        if profileState.profileStatus.nfc != .none {
            showModulePreview(module: "nfc")
        } else {
            doNfcCapture()
        }
    }
    
    private func showModulePreview(module: String) {
        contentView.setLoading(true)
        
        Task {
            let loadedProfile = await profileManager.loadProfile()
            
            await MainActor.run {
                contentView.setLoading(false)
                let primaryColor = config.theme.colors.primary
                
                switch module {
                case "document":
                    guard let documentData = loadedProfile?.document else {
                        doDocumentCapture()
                        return
                    }
                    let previewVC = DocumentPreviewViewController(
                        documentData: documentData,
                        primaryColor: primaryColor,
                        onRecapture: { [weak self] in
                            self?.dismiss(animated: true) { self?.doDocumentCapture() }
                        },
                        onClose: { [weak self] in self?.dismiss(animated: true) }
                    )
                    presentFullScreen(previewVC)
                    
                case "liveness":
                    guard let livenessData = loadedProfile?.liveness else {
                        doLivenessCapture()
                        return
                    }
                    let previewVC = LivenessPreviewViewController(
                        livenessData: livenessData,
                        primaryColor: primaryColor,
                        onRecapture: { [weak self] in
                            self?.dismiss(animated: true) { self?.doLivenessCapture() }
                        },
                        onClose: { [weak self] in self?.dismiss(animated: true) }
                    )
                    presentFullScreen(previewVC)
                    
                case "nfc":
                    guard let nfcData = loadedProfile?.nfc else {
                        doNfcCapture()
                        return
                    }
                    let previewVC = NFCPreviewViewController(
                        nfcData: nfcData,
                        primaryColor: primaryColor,
                        onRecapture: { [weak self] in
                            self?.dismiss(animated: true) { self?.doNfcCapture() }
                        },
                        onClose: { [weak self] in self?.dismiss(animated: true) }
                    )
                    presentFullScreen(previewVC)
                    
                default: break
                }
            }
        }
    }
    
    private func doDocumentCapture() {
        contentView.setLoading(true)
        let captureVC = profileManager.createDocumentCapture(completion: { [weak self] result in
            guard let self else { return }
            contentView.setLoading(false)
            
            if let documentData = result {
                Task {
                    do {
                        try await self.profileManager.saveDocumentData(documentData)
                        await self.loadStatus()
                    } catch {
                        self.handleSaveError(error, context: "document")
                    }
                }
            }
            dismiss(animated: true)
        })
        present(captureVC, animated: true)
    }
    
    private func doLivenessCapture() {
        contentView.setLoading(true)
        let captureVC = profileManager.createLivenessCapture(completion: { [weak self] result in
            guard let self else { return }
            contentView.setLoading(false)
            
            if let livenessData = result {
                Task {
                    do {
                        try await self.profileManager.saveLivenessData(livenessData)
                        await self.loadStatus()
                    } catch {
                        self.handleSaveError(error, context: "liveness")
                    }
                }
            }
            dismiss(animated: true)
        })
        present(captureVC, animated: true)
    }
    
    private func doNfcCapture() {
        contentView.setLoading(true)
        let captureVC = profileManager.createNfcCapture(completion: { [weak self] result in
            guard let self else { return }
            contentView.setLoading(false)
            
            if let nfcData = result {
                Task {
                    do {
                        try await self.profileManager.saveNfcData(nfcData)
                        await self.loadStatus()
                    } catch {
                        self.handleSaveError(error, context: "nfc")
                    }
                }
            }
            dismiss(animated: true)
        })
        present(captureVC, animated: true)
    }
    
    private func handleSaveError(_ error: Error, context: String) {
        let okidError = OkIDErrorHandler.shared.normalize(error)
        OkIDErrorHandler.shared.handle(
            error,
            context: "ProfileDashboardViewController.save\(context.capitalized)Data",
            severity: .error
        )
        contentView.showMessage(
            okidError.errorDescription ?? error.localizedDescription,
            type: .error
        )
    }
    
    // MARK: - PIN Management
    
    private func handleSecurityToggle() {
        if profileState.isPinEnabled {
            showPinOptions()
        } else {
            setupPin()
        }
    }
    
    private func showPinOptions() {
        OkIDAlert.showActionSheet(
            title: nil,
            message: nil,
            actions: [
                OkIDAlert.Action(title: "Change PIN", style: .default) { [weak self] in
                    self?.changePin()
                },
                OkIDAlert.Action(title: "Disable PIN", style: .destructive) { [weak self] in
                    self?.disablePin()
                },
                .cancel()
            ],
            from: self
        )
    }
    
    private func setupPin() {
        let pinVC = PinViewController(
            flowType: .setup,
            primaryColor: config.theme.colors.primary
        ) { [weak self] success in
            guard let self else { return }
            if success {
                Task {
                    await self.refreshPinState()
                    await MainActor.run {
                        self.contentView.showMessage("PIN protection enabled", type: .success)
                    }
                }
            }
            dismiss(animated: true)
        }
        presentFullScreen(pinVC)
    }
    
    private func changePin() {
        let pinVC = PinViewController(
            flowType: .change,
            primaryColor: config.theme.colors.primary
        ) { [weak self] success in
            guard let self else { return }
            if success {
                contentView.showMessage("PIN changed successfully", type: .success)
            }
            dismiss(animated: true)
        }
        presentFullScreen(pinVC)
    }
    
    private func disablePin() {
        let pinVC = PinViewController(
            flowType: .disable,
            primaryColor: config.theme.colors.primary
        ) { [weak self] success in
            if success {
                self?.dismiss(animated: true) {
                    self?.confirmDisablePin()
                }
            } else {
                self?.dismiss(animated: true)
            }
        }
        presentFullScreen(pinVC)
    }
    
    private func confirmDisablePin() {
        OkIDAlert.showDestructiveConfirmation(
            title: "Disable PIN?",
            message: "Your Identity Vault will no longer be protected by a PIN.",
            destructiveTitle: "Disable",
            from: self,
            onConfirm: { [weak self] in
                Task {
                    await self?.profileManager.deletePin()
                    await self?.refreshPinState()
                    await MainActor.run {
                        self?.contentView.showMessage("PIN protection disabled", type: .warning)
                    }
                }
            }
        )
    }
    
    private func refreshPinState() async {
        let pinEnabled = await profileManager.checkPinEnabled()
        await MainActor.run {
            profileState.isPinEnabled = pinEnabled
        }
    }
    
    // MARK: - Navigation Actions
    
    @objc private func closeTapped() {
        onComplete(OkIDProfileResult.success(status: profileState.profileStatus, modified: true))
    }
    
    @objc private func deleteProfileTapped() {
        OkIDAlert.showDestructiveConfirmation(
            title: "Delete Profile?",
            message: "This will permanently delete all your saved verification data. You will need to recapture everything for future verifications.",
            from: self,
            onConfirm: { [weak self] in
                Task {
                    await self?.profileManager.deleteProfile()
                    await self?.loadStatus()
                }
            }
        )
    }
    
    // MARK: - Helpers
    
    private func presentFullScreen(_ viewController: UIViewController) {
        let nav = UINavigationController(rootViewController: viewController)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}
