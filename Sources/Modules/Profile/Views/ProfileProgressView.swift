import UIKit

/// Security level progress indicator for the Profile Dashboard
/// Shows level badge, description, and 3-segment progress bar
/// Extracted from ProfileDashboardContentView following MVC pattern
class ProfileProgressView: UIView {
    
    // MARK: - Initialization
    
    init(data: ProfileProgressData) {
        super.init(frame: .zero)
        buildUI(data: data)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI
    
    private func buildUI(data: ProfileProgressData) {
        backgroundColor = UIColor.white.withAlphaComponent(0.05)
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = (data.level >= 2
            ? data.color.withAlphaComponent(0.3)
            : UIColor.white.withAlphaComponent(0.1)
        ).cgColor
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        // Level header
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .center
        
        let levelBadge = OkIDLabel()
        levelBadge.text = data.level > 0 ? "LEVEL \(data.level)" : "LEVEL 0"
        levelBadge.font = .systemFont(ofSize: 11, weight: .bold)
        levelBadge.textColor = data.color
        levelBadge.backgroundColor = data.color.withAlphaComponent(0.2)
        levelBadge.textAlignment = .center
        levelBadge.layer.cornerRadius = 8
        levelBadge.clipsToBounds = true
        levelBadge.translatesAutoresizingMaskIntoConstraints = false
        levelBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        levelBadge.heightAnchor.constraint(equalToConstant: 24).isActive = true
        headerStack.addArrangedSubview(levelBadge)
        
        let titleLabel = OkIDLabel()
        titleLabel.text = data.title
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = data.color
        headerStack.addArrangedSubview(titleLabel)
        
        stack.addArrangedSubview(headerStack)
        
        // Description
        let descLabel = OkIDLabel()
        descLabel.text = data.description
        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        stack.addArrangedSubview(descLabel)
        
        // Progress segments
        let progressStack = UIStackView()
        progressStack.axis = .horizontal
        progressStack.spacing = 4
        progressStack.distribution = .fillEqually
        
        for (index, segmentColor) in data.segmentColors.enumerated() {
            let isCurrentLevel = data.level == (index + 1)
            let segmentView = buildSegment(color: segmentColor, isCurrent: isCurrentLevel)
            progressStack.addArrangedSubview(segmentView)
        }
        
        progressStack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(progressStack)
        progressStack.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        // Labels row
        let labelsStack = UIStackView()
        labelsStack.axis = .horizontal
        labelsStack.distribution = .fillEqually
        
        for (idx, text) in ["Basic", "High", "Maximum"].enumerated() {
            let label = OkIDLabel()
            label.text = text
            label.font = .systemFont(ofSize: 10, weight: data.level == idx + 1 ? .semibold : .regular)
            label.textColor = data.level >= idx + 1
                ? UIColor.white.withAlphaComponent(0.7)
                : UIColor.white.withAlphaComponent(0.38)
            label.textAlignment = .center
            labelsStack.addArrangedSubview(label)
        }
        
        stack.addArrangedSubview(labelsStack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    private func buildSegment(color: UIColor, isCurrent: Bool) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let segmentView = UIView()
        segmentView.backgroundColor = color
        segmentView.layer.cornerRadius = 4
        segmentView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(segmentView)
        
        let verticalPadding: CGFloat = isCurrent ? 0 : 1
        
        NSLayoutConstraint.activate([
            segmentView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            segmentView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            segmentView.topAnchor.constraint(equalTo: container.topAnchor, constant: verticalPadding),
            segmentView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -verticalPadding)
        ])
        
        return container
    }
}
