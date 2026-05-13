import UIKit

/// Preview screen for NFC passport data — thin coordinator following MVC pattern
/// - Uses NFCPreviewContentView for all UI
/// - Controller coordinates data formatting and callbacks
public class NFCPreviewViewController: UIViewController {
    
    // MARK: - Properties
    
    private let nfcData: OkIDProfileNfcData
    private let primaryColor: UIColor
    private let onRecapture: () -> Void
    private let onClose: () -> Void
    
    // MARK: - Initialization
    
    public init(
        nfcData: OkIDProfileNfcData,
        primaryColor: UIColor,
        onRecapture: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.nfcData = nfcData
        self.primaryColor = primaryColor
        self.onRecapture = onRecapture
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Navigation bar
        title = "Passport Chip Data"
        navigationController?.navigationBar.barTintColor = primaryColor
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.isTranslucent = false
        
        navigationItem.leftBarButtonItem = OkIDBarButtonItem.close(
            target: self,
            action: #selector(closeTapped)
        )
        
        // Analyze photo
        var photoSize: CGSize?
        if let photoData = nfcData.photo,
           let image = UIImage(data: photoData) {
            photoSize = image.size
        }
        
        // Build data rows
        let personalInfoRows = buildPersonalInfoRows()
        let documentInfoRows = buildDocumentInfoRows()
        let chipDataRows = buildChipDataRows()
        
        // Content view
        let contentView = NFCPreviewContentView(
            nfcData: nfcData,
            primaryColor: primaryColor,
            photoSize: photoSize,
            formattedDate: formatDate(nfcData.capturedAt),
            personalInfoRows: personalInfoRows,
            documentInfoRows: documentInfoRows,
            chipDataRows: chipDataRows
        )
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        contentView.onReadPassportAgain = { [weak self] in
            self?.onRecapture()
        }
    }
    
    // MARK: - Data Row Builders
    
    private func buildPersonalInfoRows() -> [(String, String)] {
        let info = nfcData.personalInfo
        var rows: [(String, String)] = []
        
        if let firstName = info.firstName, let lastName = info.lastName {
            rows.append(("Name", "\(firstName) \(lastName)"))
        }
        if let nationality = info.nationality {
            rows.append(("Nationality", nationality))
        }
        if let dob = info.dateOfBirth {
            rows.append(("Date of Birth", formatIsoDate(dob)))
        }
        if let gender = info.gender {
            rows.append(("Gender", formatGender(gender)))
        }
        
        return rows
    }
    
    private func buildDocumentInfoRows() -> [(String, String)] {
        let info = nfcData.personalInfo
        var rows: [(String, String)] = []
        
        if let docNumber = info.documentNumber {
            rows.append(("Document Number", docNumber))
        }
        if let docType = info.documentType {
            rows.append(("Type", docType))
        }
        if let issuingState = info.issuingState {
            rows.append(("Issuing Country", issuingState))
        }
        if let expiry = info.dateOfExpiry {
            rows.append(("Expiry Date", formatIsoDate(expiry)))
        }
        
        return rows
    }
    
    private func buildChipDataRows() -> [(String, String)] {
        let dataGroups = nfcData.dataGroupsRead.joined(separator: ", ")
        let readAt = formatDate(nfcData.capturedAt)
        
        return [
            ("Data Groups", dataGroups),
            ("Read At", readAt)
        ]
    }
    
    // MARK: - Formatting Helpers
    
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatIsoDate(_ isoDate: String) -> String {
        let components = isoDate.split(separator: "-")
        guard components.count == 3,
              let month = Int(components[1]),
              month >= 1 && month <= 12 else {
            return isoDate
        }
        
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return "\(months[month - 1]) \(components[2]), \(components[0])"
    }
    
    private func formatGender(_ gender: String) -> String {
        switch gender.uppercased() {
        case "M": return "Male"
        case "F": return "Female"
        default: return gender
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        onClose()
    }
}
