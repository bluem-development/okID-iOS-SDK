import UIKit

/// Content view for NFC passport data preview — all UI elements
/// Extracted from NFCPreviewViewController following MVC pattern
class NFCPreviewContentView: UIView {
    
    // MARK: - Callbacks
    
    var onReadPassportAgain: (() -> Void)?
    
    // MARK: - Properties
    
    private let primaryColor: UIColor
    
    // MARK: - Initialization
    
    init(
        nfcData: OkIDProfileNfcData,
        primaryColor: UIColor,
        photoSize: CGSize?,
        formattedDate: String,
        personalInfoRows: [(String, String)],
        documentInfoRows: [(String, String)],
        chipDataRows: [(String, String)]
    ) {
        self.primaryColor = primaryColor
        super.init(frame: .zero)
        setupUI(
            nfcData: nfcData,
            photoSize: photoSize,
            formattedDate: formattedDate,
            personalInfoRows: personalInfoRows,
            documentInfoRows: documentInfoRows,
            chipDataRows: chipDataRows
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI(
        nfcData: OkIDProfileNfcData,
        photoSize: CGSize?,
        formattedDate: String,
        personalInfoRows: [(String, String)],
        documentInfoRows: [(String, String)],
        chipDataRows: [(String, String)]
    ) {
        backgroundColor = .okidBackgroundLightest
        
        // Scroll view
        let scrollView = OkIDScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        // Content stack
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
        // Success banner
        contentStack.addArrangedSubview(createSuccessBanner(dataGroupCount: nfcData.dataGroupsRead.count))
        
        // Photo (if available)
        if let photo = nfcData.photo {
            contentStack.addArrangedSubview(createPhotoSection(photo: photo, photoSize: photoSize))
        }
        
        // Info cards
        if !personalInfoRows.isEmpty {
            contentStack.addArrangedSubview(createInfoCard(title: "Personal Information", icon: "person", rows: personalInfoRows))
        }
        if !documentInfoRows.isEmpty {
            contentStack.addArrangedSubview(createInfoCard(title: "Document Information", icon: "doc.text", rows: documentInfoRows))
        }
        if !chipDataRows.isEmpty {
            contentStack.addArrangedSubview(createInfoCard(title: "Chip Data", icon: "antenna.radiowaves.left.and.right", rows: chipDataRows))
        }
        
        // Button container
        let buttonContainer = UIView()
        buttonContainer.backgroundColor = .white
        buttonContainer.layer.shadowColor = UIColor.black.cgColor
        buttonContainer.layer.shadowOpacity = 0.05
        buttonContainer.layer.shadowOffset = CGSize(width: 0, height: -2)
        buttonContainer.layer.shadowRadius = 10
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(buttonContainer)
        
        let readPassportButton = OkIDPrimaryButton(title: "Read Passport Again", icon: "arrow.clockwise")
        readPassportButton.translatesAutoresizingMaskIntoConstraints = false
        readPassportButton.addTarget(self, action: #selector(readPassportTapped), for: .touchUpInside)
        buttonContainer.addSubview(readPassportButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonContainer.topAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            
            buttonContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            readPassportButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor, constant: 20),
            readPassportButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor, constant: 20),
            readPassportButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor, constant: -20),
            readPassportButton.bottomAnchor.constraint(equalTo: buttonContainer.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - UI Builders
    
    private func createSuccessBanner(dataGroupCount: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = .okidSuccessLight
        container.layer.cornerRadius = 10
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.okidSuccessBorder.cgColor
        
        let iconView = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
        iconView.tintColor = .okidSuccess
        iconView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconView)
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textStack)
        
        let titleLabel = OkIDLabel()
        titleLabel.text = "Chip Read Successful"
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .okidSuccess
        textStack.addArrangedSubview(titleLabel)
        
        let subtitleLabel = OkIDLabel()
        subtitleLabel.text = "\(dataGroupCount) data groups extracted"
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .gray
        textStack.addArrangedSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),
            
            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            textStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        
        return container
    }
    
    private func createPhotoSection(photo: Data, photoSize: CGSize?) -> UIView {
        let container = UIView()
        
        let photoContainer = UIView()
        photoContainer.backgroundColor = .white
        photoContainer.layer.cornerRadius = 12
        photoContainer.layer.shadowColor = UIColor.black.cgColor
        photoContainer.layer.shadowOpacity = 0.1
        photoContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        photoContainer.layer.shadowRadius = 10
        photoContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(photoContainer)
        
        let photoImageView = UIImageView(image: UIImage(data: photo))
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.layer.cornerRadius = 12
        photoImageView.clipsToBounds = true
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        photoContainer.addSubview(photoImageView)
        
        NSLayoutConstraint.activate([
            photoContainer.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            photoContainer.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            photoContainer.widthAnchor.constraint(equalToConstant: 120),
            photoContainer.heightAnchor.constraint(equalToConstant: 150),
            
            photoImageView.topAnchor.constraint(equalTo: photoContainer.topAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: photoContainer.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: photoContainer.trailingAnchor),
            photoImageView.bottomAnchor.constraint(equalTo: photoContainer.bottomAnchor)
        ])
        
        if let size = photoSize {
            let sizeLabel = OkIDLabel()
            sizeLabel.text = "Photo: \(Int(size.width))×\(Int(size.height))px"
            sizeLabel.font = .systemFont(ofSize: 11)
            sizeLabel.textColor = .gray
            sizeLabel.textAlignment = .center
            sizeLabel.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(sizeLabel)
            
            NSLayoutConstraint.activate([
                sizeLabel.topAnchor.constraint(equalTo: photoContainer.bottomAnchor, constant: 8),
                sizeLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                sizeLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
            ])
        } else {
            photoContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20).isActive = true
        }
        
        return container
    }
    
    private func createInfoCard(title: String, icon: String, rows: [(String, String)]) -> UIView {
        guard !rows.isEmpty else { return UIView() }
        
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.okidGray200.cgColor
        
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(headerStack)
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = primaryColor
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        headerStack.addArrangedSubview(iconView)
        
        let titleLabel = OkIDLabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .okidTextPrimary
        headerStack.addArrangedSubview(titleLabel)
        
        let divider = UIView()
        divider.backgroundColor = .okidGray200
        divider.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(divider)
        
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(contentStack)
        
        for (label, value) in rows {
            contentStack.addArrangedSubview(createInfoRow(label: label, value: value))
        }
        
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            divider.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 16),
            divider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),
            
            contentStack.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        return container
    }
    
    private func createInfoRow(label: String, value: String) -> UIView {
        let container = UIView()
        
        let labelView = OkIDLabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 13)
        labelView.textColor = .gray
        labelView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(labelView)
        
        let valueLabel = OkIDLabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14, weight: .medium)
        valueLabel.textColor = .okidTextPrimary
        valueLabel.numberOfLines = 0
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: container.topAnchor),
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelView.widthAnchor.constraint(equalToConstant: 120),
            labelView.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor),
            
            valueLabel.topAnchor.constraint(equalTo: container.topAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    // MARK: - Actions
    
    @objc private func readPassportTapped() {
        onReadPassportAgain?()
    }
}
