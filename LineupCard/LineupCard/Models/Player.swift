import Foundation

struct Player: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var number: Int
    var surname: String
    var isCaptain: Bool = false

    init(number: Int = 1, surname: String = "", isCaptain: Bool = false) {
        self.number = number
        self.surname = surname
        self.isCaptain = isCaptain
    }
}
