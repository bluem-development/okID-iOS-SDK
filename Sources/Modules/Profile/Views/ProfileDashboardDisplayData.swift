import UIKit

// MARK: - Display Data Models

/// Pre-computed display data for a module card
/// The controller prepares this from the Manager, so the View never touches the Manager
struct ProfileModuleCardData {
    let moduleKey: String
    let icon: String
    let title: String
    let isCaptured: Bool
    let isOptional: Bool
    let statusColor: UIColor
    let statusText: String
    let tierHint: String?
    let statusBadgeIcon: String?   // "checkmark" or "clock", nil if not captured
    let primaryColor: UIColor
}

/// Pre-computed display data for the progress indicator
struct ProfileProgressData {
    let level: Int
    let title: String
    let description: String
    let color: UIColor
    let segmentColors: [UIColor]   // exactly 3 elements, one per segment
}

/// Pre-computed display data for the security toggle
struct ProfileSecurityToggleData {
    let isPinEnabled: Bool
    let primaryColor: UIColor
}

/// Pre-computed display data for the title section
struct ProfileTitleSectionData {
    let primaryColor: UIColor
}

/// All data needed to build the dashboard content
struct ProfileDashboardDisplayData {
    let titleData: ProfileTitleSectionData
    let progressData: ProfileProgressData
    let moduleCards: [ProfileModuleCardData]
    let securityToggle: ProfileSecurityToggleData
}
