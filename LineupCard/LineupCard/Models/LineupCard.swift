import Foundation
import SwiftUI

// MARK: - NumberStyle (display toggle)

enum NumberStyle: String, Codable, CaseIterable {
    case decimal = "decimal"  // ".31" after name
    case integer = "integer"  // "31" before name (integer)

    var displayName: String {
        switch self {
        case .decimal: return ".31 (Man Utd)"
        case .integer: return "31 (standard)"
        }
    }
}

// MARK: - LineupCard

struct LineupCard: Identifiable, Codable {
    var id: UUID = UUID()
    var titleWord: String = "STARTING"
    var matchLabel: String = ""
    var starters: [Player] = []
    var bench: [Player] = []
    var managerName: String = ""
    var sponsorLine: String = ""
    var themePreset: ThemePreset = .manUtdDark
    var customTheme: CustomTheme?
    var backgroundImageData: Data?
    var playerPhotoData: Data?
    var badge1Data: Data?
    var badge2Data: Data?
    var createdAt: Date = Date()

    // MARK: Computed

    var romanNumeral: String {
        RomanNumeralHelper.convert(starters.count)
    }

    var resolvedTheme: TeamTheme {
        if themePreset == .custom, let ct = customTheme {
            return ct.asTeamTheme
        }
        return themePreset.theme
    }
}

// MARK: - CardStore

class CardStore: ObservableObject {
    @Published var cards: [LineupCard] = []

    private let storageKey = "lineup_cards_v1"

    init() { load() }

    func save(_ card: LineupCard) {
        if let idx = cards.firstIndex(where: { $0.id == card.id }) {
            cards[idx] = card
        } else {
            cards.insert(card, at: 0)
        }
        persist()
    }

    func delete(_ card: LineupCard) {
        cards.removeAll { $0.id == card.id }
        persist()
    }

    func duplicate(_ card: LineupCard) {
        var copy = card
        copy.id = UUID()
        copy.createdAt = Date()
        cards.insert(copy, at: 0)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(cards) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let saved = try? JSONDecoder().decode([LineupCard].self, from: data)
        else { return }
        cards = saved
    }
}
