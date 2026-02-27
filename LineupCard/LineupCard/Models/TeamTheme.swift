import SwiftUI

// MARK: - Enums

enum NumberPlacement: String, Codable, CaseIterable {
    case leftInteger   // "31  PLAYER"
    case rightDecimal  // "PLAYER .31"
}

enum BackgroundStyle: String, Codable, CaseIterable {
    case solid
    case gradient
    case blurredPhoto
}

enum PlayerListAlignment: String, Codable {
    case leading
    case center
    case trailing
}

// MARK: - TeamTheme (runtime only, not Codable)

struct TeamTheme {
    var backgroundColor: Color
    var accentColor: Color
    var textColor: Color
    var numberColor: Color
    var subsTextColor: Color
    var playerPhotoEnabled: Bool
    var backgroundStyle: BackgroundStyle
    var numberPlacement: NumberPlacement
    var listAlignment: PlayerListAlignment
    var showLeftPanel: Bool     // whether left photo panel exists in layout
    var leftPanelWidth: CGFloat // fraction of card width (0.0–1.0)
}

// MARK: - Custom Theme (Codable storage)

struct CustomTheme: Codable {
    var backgroundHex: String = "0A0A0A"
    var accentHex: String = "CC0000"
    var textHex: String = "FFFFFF"
    var numberHex: String = "FFFFFF"
    var playerPhotoEnabled: Bool = true
    var backgroundStyle: BackgroundStyle = .solid
    var numberPlacement: NumberPlacement = .rightDecimal

    var asTeamTheme: TeamTheme {
        TeamTheme(
            backgroundColor: Color(hex: backgroundHex),
            accentColor: Color(hex: accentHex),
            textColor: Color(hex: textHex),
            numberColor: Color(hex: numberHex),
            subsTextColor: Color(hex: textHex).opacity(0.75),
            playerPhotoEnabled: playerPhotoEnabled,
            backgroundStyle: backgroundStyle,
            numberPlacement: numberPlacement,
            listAlignment: numberPlacement == .rightDecimal ? .trailing : .leading,
            showLeftPanel: playerPhotoEnabled,
            leftPanelWidth: 0.45
        )
    }
}

// MARK: - ThemePreset

enum ThemePreset: String, Codable, CaseIterable, Identifiable {
    case manUtdDark = "manUtdDark"
    case manUtdAway = "manUtdAway"
    case liverpool = "liverpool"
    case norwich = "norwich"
    case realMadrid = "realMadrid"
    case barcelona = "barcelona"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .manUtdDark: return "Man Utd"
        case .manUtdAway: return "Man Utd Away"
        case .liverpool:  return "Liverpool"
        case .norwich:    return "Norwich"
        case .realMadrid: return "Real Madrid"
        case .barcelona:  return "Barcelona"
        case .custom:     return "Custom"
        }
    }

    var defaultNumberStyle: NumberPlacement {
        switch self {
        case .manUtdDark, .manUtdAway: return .rightDecimal
        default: return .leftInteger
        }
    }

    var theme: TeamTheme {
        switch self {

        case .manUtdDark:
            return TeamTheme(
                backgroundColor: Color(hex: "0A0A0A"),
                accentColor: Color(hex: "CC0000"),
                textColor: .white,
                numberColor: Color.white.opacity(0.65),
                subsTextColor: Color.white.opacity(0.6),
                playerPhotoEnabled: true,
                backgroundStyle: .solid,
                numberPlacement: .rightDecimal,
                listAlignment: .trailing,
                showLeftPanel: true,
                leftPanelWidth: 0.48
            )

        case .manUtdAway:
            return TeamTheme(
                backgroundColor: Color(hex: "080808"),
                accentColor: Color(hex: "D4AF37"),
                textColor: .white,
                numberColor: Color(hex: "D4AF37"),
                subsTextColor: Color(hex: "D4AF37").opacity(0.7),
                playerPhotoEnabled: true,
                backgroundStyle: .solid,
                numberPlacement: .rightDecimal,
                listAlignment: .trailing,
                showLeftPanel: true,
                leftPanelWidth: 0.48
            )

        case .liverpool:
            return TeamTheme(
                backgroundColor: Color(hex: "C8102E"),
                accentColor: .white,
                textColor: .white,
                numberColor: Color.white.opacity(0.55),
                subsTextColor: Color.white.opacity(0.75),
                playerPhotoEnabled: false,
                backgroundStyle: .solid,
                numberPlacement: .leftInteger,
                listAlignment: .leading,
                showLeftPanel: false,
                leftPanelWidth: 0.0
            )

        case .norwich:
            return TeamTheme(
                backgroundColor: Color(hex: "FFF200"),
                accentColor: Color(hex: "00A651"),
                textColor: Color(hex: "1A1A1A"),
                numberColor: Color(hex: "00A651"),
                subsTextColor: Color(hex: "1A1A1A").opacity(0.7),
                playerPhotoEnabled: true,
                backgroundStyle: .solid,
                numberPlacement: .leftInteger,
                listAlignment: .leading,
                showLeftPanel: true,
                leftPanelWidth: 0.42
            )

        case .realMadrid:
            return TeamTheme(
                backgroundColor: Color(hex: "0D1B4B"),
                accentColor: Color(hex: "1E6FDB"),
                textColor: .white,
                numberColor: Color.white.opacity(0.55),
                subsTextColor: Color.white.opacity(0.7),
                playerPhotoEnabled: true,
                backgroundStyle: .blurredPhoto,
                numberPlacement: .leftInteger,
                listAlignment: .leading,
                showLeftPanel: true,
                leftPanelWidth: 0.44
            )

        case .barcelona:
            return TeamTheme(
                backgroundColor: Color(hex: "0A1628"),
                accentColor: Color(hex: "A50044"),
                textColor: .white,
                numberColor: Color(hex: "0057A8"),
                subsTextColor: Color.white.opacity(0.65),
                playerPhotoEnabled: true,
                backgroundStyle: .solid,
                numberPlacement: .leftInteger,
                listAlignment: .leading,
                showLeftPanel: true,
                leftPanelWidth: 0.44
            )

        case .custom:
            return TeamTheme(
                backgroundColor: Color(hex: "0A0A0A"),
                accentColor: Color(hex: "CC0000"),
                textColor: .white,
                numberColor: .white,
                subsTextColor: Color.white.opacity(0.7),
                playerPhotoEnabled: true,
                backgroundStyle: .solid,
                numberPlacement: .rightDecimal,
                listAlignment: .trailing,
                showLeftPanel: true,
                leftPanelWidth: 0.45
            )
        }
    }
}
