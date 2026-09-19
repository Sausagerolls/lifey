import Foundation

/// Everything a table sets up once and wants back next time: seat count, life total,
/// arrangement, who sits where, and which counters are on screen.
struct GameConfig: Codable, Equatable {
    var playerCount: Int = 2
    var startingLife: Int = 40
    var layout: SeatLayout = .duel
    var enabledCounters: [CounterKind] = CounterKind.commanderDefaults
    /// Counters the table made up, shown alongside the built-in ones.
    var customCounters: [CustomCounter] = []
    var commanderDamageEnabled: Bool = true
    var commanderDamageAffectsLife: Bool = true
    var partnerCommanders: Bool = false
    /// Indexed by seat slot, so seat 0 keeps its colour and name across games.
    var seatNames: [String] = GameConfig.defaultNames(4)
    var seatAccents: [String] = GameConfig.defaultAccents(4)
    var hapticsEnabled: Bool = true
    var soundEnabled: Bool = true
    var keepScreenAwake: Bool = true

    init() {}

    /// Decoded field by field so a default saved by an older version still loads when
    /// new settings appear.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playerCount = try container.decodeIfPresent(Int.self, forKey: .playerCount) ?? 2
        startingLife = try container.decodeIfPresent(Int.self, forKey: .startingLife) ?? 40
        layout = try container.decodeIfPresent(SeatLayout.self, forKey: .layout) ?? .duel
        enabledCounters = try container.decodeIfPresent([CounterKind].self, forKey: .enabledCounters)
            ?? CounterKind.commanderDefaults
        customCounters = try container.decodeIfPresent([CustomCounter].self, forKey: .customCounters) ?? []
        commanderDamageEnabled = try container.decodeIfPresent(Bool.self, forKey: .commanderDamageEnabled) ?? true
        commanderDamageAffectsLife = try container.decodeIfPresent(Bool.self, forKey: .commanderDamageAffectsLife) ?? true
        partnerCommanders = try container.decodeIfPresent(Bool.self, forKey: .partnerCommanders) ?? false
        seatNames = try container.decodeIfPresent([String].self, forKey: .seatNames) ?? GameConfig.defaultNames(4)
        seatAccents = try container.decodeIfPresent([String].self, forKey: .seatAccents) ?? GameConfig.defaultAccents(4)
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        keepScreenAwake = try container.decodeIfPresent(Bool.self, forKey: .keepScreenAwake) ?? true
    }

    static func defaultNames(_ count: Int) -> [String] {
        (0..<count).map { "Player \($0 + 1)" }
    }

    static func defaultAccents(_ count: Int) -> [String] {
        (0..<count).map { Accent.forSeat($0).id }
    }

    func name(forSeat seat: Int) -> String {
        seat < seatNames.count ? seatNames[seat] : "Player \(seat + 1)"
    }

    func accentID(forSeat seat: Int) -> String {
        seat < seatAccents.count ? seatAccents[seat] : Accent.forSeat(seat).id
    }

    /// Built-in counters that are switched on, followed by the table's own counters.
    var counterDefinitions: [CounterDefinition] {
        enabledCounters.map(CounterDefinition.init(kind:))
            + customCounters.map(CounterDefinition.init(custom:))
    }

    /// Keeps the arrangement legal after the player count changes.
    mutating func normalize() {
        playerCount = min(max(playerCount, 2), 4)
        if layout.playerCount != playerCount {
            layout = SeatLayout.first(forPlayerCount: playerCount)
        }
        while seatNames.count < 4 { seatNames.append("Player \(seatNames.count + 1)") }
        while seatAccents.count < 4 { seatAccents.append(Accent.forSeat(seatAccents.count).id) }
    }
}
