import Combine
import SwiftUI

/// Saved snapshot of a game in progress, so closing the app mid-match loses nothing.
private struct PersistedGame: Codable {
    var config: GameConfig
    var players: [Player]
}

@MainActor
final class GameStore: ObservableObject {
    enum Phase: Equatable {
        case setup
        case playing
    }

    @Published var config: GameConfig {
        didSet { syncFeedbackSettings() }
    }
    @Published private(set) var players: [Player] = []
    @Published var phase: Phase = .setup
    /// The arrangement the table saved with "Save as default", if they have saved one.
    @Published private(set) var savedDefault: GameConfig?

    private let defaults = UserDefaults.standard
    private let defaultConfigKey = "lifey.defaultConfig"
    private let currentGameKey = "lifey.currentGame"

    init() {
        let stored = Self.decode(GameConfig.self, from: defaults.data(forKey: defaultConfigKey))
        savedDefault = stored
        config = stored ?? GameConfig()
        config.normalize()
        syncFeedbackSettings()

        if let resumed = Self.decode(PersistedGame.self, from: defaults.data(forKey: currentGameKey)),
           resumed.players.count == resumed.config.playerCount {
            config = resumed.config
            players = resumed.players
            phase = .playing
        }
    }

    // MARK: - Game lifecycle

    /// Deals a fresh set of players from the current configuration.
    func startGame() {
        config.normalize()
        players = (0..<config.playerCount).map { seat in
            Player(
                name: config.name(forSeat: seat),
                accentID: config.accentID(forSeat: seat),
                life: config.startingLife,
                commanderCount: config.partnerCommanders ? 2 : 1
            )
        }
        phase = .playing
        persistGame()
    }

    /// Same players and seats, totals back to the starting position.
    func resetTotals() {
        for index in players.indices {
            players[index].life = config.startingLife
            players[index].counters = [:]
            players[index].commanderDamage = [:]
        }
        persistGame()
    }

    func returnToSetup() {
        phase = .setup
        defaults.removeObject(forKey: currentGameKey)
    }

    // MARK: - Totals

    func adjustLife(playerID: UUID, by amount: Int) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        let wasEliminated = players[index].isEliminated
        players[index].life += amount
        reportChange(wasEliminated: wasEliminated, index: index)
    }

    func setLife(playerID: UUID, to value: Int) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[index].life = value
        persistGame()
    }

    /// Takes the counter's definition id, so built-in and custom counters share one path.
    func adjustCounter(playerID: UUID, counterID: String, by amount: Int) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        let wasEliminated = players[index].isEliminated
        let next = max(0, players[index].counter(id: counterID) + amount)
        players[index].counters[counterID] = next
        reportChange(wasEliminated: wasEliminated, index: index)
    }

    // MARK: - Custom counters

    func addCustomCounter(_ counter: CustomCounter) {
        config.customCounters.append(counter)
        persistGame()
    }

    func updateCustomCounter(_ counter: CustomCounter) {
        guard let index = config.customCounters.firstIndex(where: { $0.id == counter.id }) else { return }
        config.customCounters[index] = counter
        persistGame()
    }

    /// Removes the counter from every panel. Totals already recorded are left in place,
    /// so bringing the counter back also brings its numbers back.
    func removeCustomCounter(id: String) {
        config.customCounters.removeAll { $0.id == id }
        persistGame()
    }

    /// Commander damage is tracked per attacking commander and, unless switched off,
    /// takes the same amount off the defender's life.
    func adjustCommanderDamage(targetID: UUID, sourceID: UUID, commanderIndex: Int, by amount: Int) {
        guard let index = players.firstIndex(where: { $0.id == targetID }) else { return }
        let key = Player.commanderKey(source: sourceID, index: commanderIndex)
        let current = players[index].commanderDamage[key] ?? 0
        let next = max(0, current + amount)
        let applied = next - current
        guard applied != 0 else { return }

        let wasEliminated = players[index].isEliminated
        players[index].commanderDamage[key] = next
        if config.commanderDamageAffectsLife {
            players[index].life -= applied
        }
        reportChange(wasEliminated: wasEliminated, index: index)
    }

    func rename(playerID: UUID, to name: String) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[index].name = name
        if index < config.seatNames.count { config.seatNames[index] = name }
        persistGame()
    }

    func setAccent(playerID: UUID, accentID: String) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[index].accentID = accentID
        if index < config.seatAccents.count { config.seatAccents[index] = accentID }
        persistGame()
    }

    func setCommanderCount(playerID: UUID, to count: Int) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[index].commanderCount = min(max(count, 1), 2)
        persistGame()
    }

    // MARK: - Lookups

    func player(at seat: Int) -> Player? {
        seat < players.count ? players[seat] : nil
    }

    /// Damage one of a player's commanders has dealt to a given opponent.
    func commanderDamage(from sourceID: UUID, commanderIndex: Int, to targetID: UUID) -> Int {
        guard let target = players.first(where: { $0.id == targetID }) else { return 0 }
        return target.commanderDamage(from: sourceID, index: commanderIndex)
    }

    /// The heaviest hit any of this player's commanders has landed, for the panel chip.
    func worstCommanderDamageDealt(by sourceID: UUID) -> Int {
        var worst = 0
        for target in players where target.id != sourceID {
            for (key, value) in target.commanderDamage
            where key.hasPrefix(sourceID.uuidString) {
                worst = max(worst, value)
            }
        }
        return worst
    }

    func opponents(of playerID: UUID) -> [Player] {
        players.filter { $0.id != playerID }
    }

    func accent(for player: Player) -> Accent {
        Accent.named(player.accentID)
    }

    // MARK: - Saved default

    /// Stores the current setup, including seats, colours and counter sections, as the
    /// arrangement Lifey opens with next time.
    func saveAsDefault() {
        var snapshot = config
        snapshot.normalize()
        for (index, player) in players.enumerated() where index < snapshot.seatNames.count {
            snapshot.seatNames[index] = player.name
            snapshot.seatAccents[index] = player.accentID
        }
        savedDefault = snapshot
        // Only republish when the snapshot actually differs, so saving never disturbs
        // anything the table is in the middle of editing.
        if config != snapshot {
            config = snapshot
        }
        defaults.set(Self.encode(snapshot), forKey: defaultConfigKey)
        persistGame()
    }

    func clearDefault() {
        savedDefault = nil
        defaults.removeObject(forKey: defaultConfigKey)
    }

    /// True when the current setup already matches what was saved.
    var matchesSavedDefault: Bool {
        guard let savedDefault else { return false }
        var snapshot = config
        for (index, player) in players.enumerated() where index < snapshot.seatNames.count {
            snapshot.seatNames[index] = player.name
            snapshot.seatAccents[index] = player.accentID
        }
        return snapshot == savedDefault
    }

    func loadSavedDefault() {
        guard let savedDefault else { return }
        config = savedDefault
        config.normalize()
    }

    // MARK: - Private

    private func reportChange(wasEliminated: Bool, index: Int) {
        if !wasEliminated, players[index].isEliminated {
            Feedback.shared.lethal()
        }
        persistGame()
    }

    private func syncFeedbackSettings() {
        Feedback.shared.hapticsEnabled = config.hapticsEnabled
        Feedback.shared.soundEnabled = config.soundEnabled
        UIApplication.shared.isIdleTimerDisabled = config.keepScreenAwake
    }

    private func persistGame() {
        guard phase == .playing else { return }
        defaults.set(Self.encode(PersistedGame(config: config, players: players)), forKey: currentGameKey)
    }

    private static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
