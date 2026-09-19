import SwiftUI

/// Every non-life total Lifey can track. Each player enables the ones their table uses.
enum CounterKind: String, CaseIterable, Identifiable, Codable {
    case poison
    case energy
    case experience
    case rad
    case ticket
    case storm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .poison: return "Poison"
        case .energy: return "Energy"
        case .experience: return "Experience"
        case .rad: return "Rad"
        case .ticket: return "Tickets"
        case .storm: return "Storm"
        }
    }

    /// Three letters or fewer, for the chips along the bottom of a panel.
    var abbreviation: String {
        switch self {
        case .poison: return "PSN"
        case .energy: return "NRG"
        case .experience: return "EXP"
        case .rad: return "RAD"
        case .ticket: return "TKT"
        case .storm: return "STM"
        }
    }

    var symbol: String {
        switch self {
        case .poison: return "drop.fill"
        case .energy: return "bolt.fill"
        case .experience: return "star.fill"
        case .rad: return "atom"
        case .ticket: return "ticket.fill"
        case .storm: return "cloud.bolt.rain.fill"
        }
    }

    var tint: Color {
        switch self {
        case .poison: return Color(hex: 0x6ED66E)
        case .energy: return Color(hex: 0x66E0FF)
        case .experience: return Color(hex: 0xFFD166)
        case .rad: return Color(hex: 0xB6FF5C)
        case .ticket: return Color(hex: 0xFF9E6D)
        case .storm: return Color(hex: 0xC2A6FF)
        }
    }

    /// The value at which this counter kills its owner, if any.
    var lethalThreshold: Int? {
        switch self {
        case .poison: return 10
        case .rad: return nil
        default: return nil
        }
    }

    /// Counters a Commander table expects to see switched on out of the box.
    static let commanderDefaults: [CounterKind] = [.poison, .experience]
}

/// A counter the table invented: energy reserve, monarch turns, a house rule, anything.
struct CustomCounter: Codable, Equatable, Identifiable {
    var id: String = "custom." + UUID().uuidString
    var title: String
    var abbreviation: String
    var symbol: String
    var colorHex: UInt32

    var tint: Color { Color(hex: colorHex) }

    /// Symbols offered in the editor, kept to shapes that stay readable at chip size.
    static let symbolChoices = [
        "star.fill", "flame.fill", "leaf.fill", "shield.fill",
        "crown.fill", "hammer.fill", "eye.fill", "moon.fill",
        "sun.max.fill", "sparkles", "target", "pawprint.fill",
        "cube.fill", "diamond.fill", "seal.fill", "bandage.fill",
        "hourglass", "flag.fill", "wand.and.stars", "circle.hexagongrid.fill",
    ]

    static let colorChoices: [UInt32] = [
        0xFF4D6D, 0x4CC9F0, 0x3DDC97, 0xFFB454,
        0xB388FF, 0xFF7AB6, 0xC8F04D, 0xA8B8D8,
    ]

    /// Three letters from the name, used when the table does not set one.
    static func suggestedAbbreviation(from title: String) -> String {
        let letters = title.uppercased().filter { $0.isLetter || $0.isNumber }
        return String(letters.prefix(3))
    }
}

/// One entry in a panel's counter row, whether it came from the built-in list or the table.
struct CounterDefinition: Identifiable, Equatable {
    let id: String
    let title: String
    let abbreviation: String
    let symbol: String
    let tint: Color
    let lethalThreshold: Int?
    let isCustom: Bool

    init(kind: CounterKind) {
        id = kind.rawValue
        title = kind.title
        abbreviation = kind.abbreviation
        symbol = kind.symbol
        tint = kind.tint
        lethalThreshold = kind.lethalThreshold
        isCustom = false
    }

    init(custom: CustomCounter) {
        id = custom.id
        title = custom.title
        abbreviation = custom.abbreviation.isEmpty
            ? CustomCounter.suggestedAbbreviation(from: custom.title)
            : custom.abbreviation
        symbol = custom.symbol
        tint = custom.tint
        lethalThreshold = nil
        isCustom = true
    }
}
