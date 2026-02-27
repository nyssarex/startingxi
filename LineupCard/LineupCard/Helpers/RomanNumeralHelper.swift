import Foundation

enum RomanNumeralHelper {
    static func convert(_ number: Int) -> String {
        guard number > 0 else { return "XI" }
        let values: [(Int, String)] = [
            (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
            (100, "C"),  (90, "XC"),  (50, "L"),  (40, "XL"),
            (10, "X"),   (9, "IX"),   (5, "V"),   (4, "IV"),
            (1, "I")
        ]
        var result = ""
        var remaining = number
        for (value, numeral) in values {
            while remaining >= value {
                result += numeral
                remaining -= value
            }
        }
        return result
    }
}
