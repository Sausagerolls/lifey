import Foundation

/// One seat's running totals for the current game.
struct Player: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var accentID: String
    var life: Int
    /// Counter totals keyed by `CounterKind.rawValue`.
    var counters: [String: Int] = [:]
    /// Commander damage taken, keyed by `Player.commanderKey(source:index:)`.
    var commanderDamage: [String: Int] = [:]
    /// 1 for a single commander, 2 when the deck runs partners or a background.
    var commanderCount: Int = 1

    func counter(_ kind: CounterKind) -> Int {
        counters[kind.rawValue] ?? 0
    }

    /// Works for built-in and custom counters alike, both keyed by their definition id.
    func counter(id: String) -> Int {
        counters[id] ?? 0
    }

    func commanderDamage(from source: UUID, index: Int) -> Int {
        commanderDamage[Player.commanderKey(source: source, index: index)] ?? 0
    }

    /// The highest single commander's damage on this player, used for the lethal badge.
    var worstCommanderDamage: Int {
        commanderDamage.values.max() ?? 0
    }

    var isEliminated: Bool {
        if life <= 0 { return true }
        if let poisonLimit = CounterKind.poison.lethalThreshold, counter(.poison) >= poisonLimit { return true }
        return worstCommanderDamage >= 21
    }

    static func commanderKey(source: UUID, index: Int) -> String {
        "\(source.uuidString)#\(index)"
    }
}
