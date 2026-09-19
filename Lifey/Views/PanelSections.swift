import SwiftUI

/// Commander damage for this panel. It opens on what this player's own commanders have
/// dealt, and a switch shows what they have taken from each opposing commander instead.
/// 21 from a single commander is lethal, so a tile turns red as it gets there.
struct CommanderSection: View {
    enum Direction: String, CaseIterable, Identifiable {
        case dealt
        case taken

        var id: String { rawValue }
        var title: String { self == .dealt ? "DEALT" : "TAKEN" }
    }

    let player: Player
    let accent: Accent
    let shortSide: CGFloat
    /// Called with the opponent taking the hit, which of this player's commanders
    /// landed it, and the amount. Only the dealt side changes anything.
    let onChange: (UUID, Int, Int) -> Void

    @EnvironmentObject private var store: GameStore
    @State private var direction: Direction = .dealt

    private struct Entry: Identifiable {
        let id: String
        /// The player on the other side of this number.
        let other: Player
        let commanderIndex: Int
        let value: Int
        /// True when the other player runs more than one commander worth labelling.
        let showsCommanderMark: Bool
    }

    private var entries: [Entry] {
        switch direction {
        case .dealt:
            let commanderCount = max(player.commanderCount, 1)
            return store.opponents(of: player.id).flatMap { opponent in
                (0..<commanderCount).map { index in
                    Entry(
                        id: "dealt-\(opponent.id.uuidString)#\(index)",
                        other: opponent,
                        commanderIndex: index,
                        value: store.commanderDamage(
                            from: player.id,
                            commanderIndex: index,
                            to: opponent.id
                        ),
                        showsCommanderMark: commanderCount > 1
                    )
                }
            }
        case .taken:
            return store.opponents(of: player.id).flatMap { opponent in
                (0..<max(opponent.commanderCount, 1)).map { index in
                    Entry(
                        id: "taken-\(opponent.id.uuidString)#\(index)",
                        other: opponent,
                        commanderIndex: index,
                        value: player.commanderDamage(from: opponent.id, index: index),
                        showsCommanderMark: opponent.commanderCount > 1
                    )
                }
            }
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            directionSwitch
            GeometryReader { geo in
                grid(in: geo.size)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Two pills at the top of the section: what this player dealt, what they took.
    private var directionSwitch: some View {
        HStack(spacing: 4) {
            ForEach(Direction.allCases) { option in
                Button {
                    Feedback.shared.select()
                    withAnimation(.snappy(duration: 0.18)) { direction = option }
                } label: {
                    Text(option.title)
                        .font(.tally(min(max(shortSide * 0.055, 10), 13), weight: .heavy))
                        .tracking(1)
                        .foregroundStyle(direction == option ? .black : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, min(max(shortSide * 0.022, 4), 7))
                        .background(
                            Capsule(style: .continuous)
                                .fill(direction == option ? accent.color : Color.black.opacity(0.25))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: min(shortSide * 1.6, 240))
    }

    private func grid(in size: CGSize) -> some View {
        let spacing: CGFloat = 6
        let columns = columnCount(for: size)
        let rowCount = max(Int(ceil(Double(entries.count) / Double(columns))), 1)
        let usableHeight = size.height - spacing * CGFloat(rowCount - 1)
        let tileHeight = max(usableHeight / CGFloat(rowCount), 40)
        let tileWidth = max((size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns), 60)
        // The buttons never grow past a quarter of the tile, so the number keeps its room.
        let buttonSize = min(max(min(tileHeight * 0.46, tileWidth * 0.25), 22), 52)

        return grid(
            columns: columns,
            spacing: spacing,
            size: size,
            tileHeight: tileHeight,
            tileWidth: tileWidth,
            buttonSize: buttonSize
        )
    }

    private func grid(
        columns: Int,
        spacing: CGFloat,
        size: CGSize,
        tileHeight: CGFloat,
        tileWidth: CGFloat,
        buttonSize: CGFloat
    ) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            ForEach(entries) { entry in
                tile(for: entry, buttonSize: buttonSize, tileHeight: tileHeight, tileWidth: tileWidth)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .center)
    }

    /// Picks the column count whose tiles come closest to a comfortable landscape shape,
    /// so three opponents sit in one row on a wide panel and two rows on a squat one.
    private func columnCount(for size: CGSize) -> Int {
        let count = entries.count
        guard count > 1 else { return 1 }
        var best = 1
        var bestScore = Double.greatestFiniteMagnitude
        for columns in 1...count {
            let rows = Int(ceil(Double(count) / Double(columns)))
            let tileWidth = size.width / Double(columns)
            let tileHeight = size.height / Double(rows)
            guard tileHeight > 0 else { continue }
            let score = abs(tileWidth / tileHeight - 2.1)
            // On a tie prefer more columns: wider rows crowd the minus and plus buttons.
            if score <= bestScore {
                bestScore = score
                best = columns
            }
        }
        return best
    }

    private func tile(for entry: Entry, buttonSize: CGFloat, tileHeight: CGFloat, tileWidth: CGFloat) -> some View {
        let lethal = entry.value >= 21
        let otherAccent = Accent.named(entry.other.accentID)
        let markTint = direction == .dealt ? accent.color : otherAccent.color

        return VStack(spacing: 2) {
            HStack(spacing: 5) {
                Circle()
                    .fill(otherAccent.color)
                    .frame(width: 8, height: 8)
                Text(entry.other.name)
                    .font(.tally(min(max(tileHeight * 0.16, 10), 14), weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                if entry.showsCommanderMark {
                    Text(entry.commanderIndex == 0 ? "I" : "II")
                        .font(.tally(min(max(shortSide * 0.05, 9), 12), weight: .heavy))
                        .foregroundStyle(markTint)
                }
            }

            HStack(spacing: 4) {
                if direction == .dealt {
                    StepButton(symbol: "minus", amount: -1, size: buttonSize) {
                        onChange(entry.other.id, entry.commanderIndex, $0)
                    }
                }

                Text("\(entry.value)")
                    .font(.tally(min(max(min(tileHeight * 0.52, tileWidth * (direction == .dealt ? 0.3 : 0.5)), 20), 60), weight: .heavy))
                    .foregroundStyle(lethal ? Theme.danger : Theme.textPrimary)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .contentTransition(.numericText(value: Double(entry.value)))
                    .animation(.snappy(duration: 0.18), value: entry.value)

                if direction == .dealt {
                    StepButton(symbol: "plus", amount: 1, size: buttonSize) {
                        onChange(entry.other.id, entry.commanderIndex, $0)
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, minHeight: tileHeight, maxHeight: tileHeight)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(direction == .dealt ? 0.28 : 0.20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(lethal ? Theme.danger : Color.white.opacity(0.10), lineWidth: lethal ? 2 : 1)
        )
    }
}

/// A round press-and-hold button used inside the commander tiles.
struct StepButton: View {
    let symbol: String
    let amount: Int
    let size: CGFloat
    let perform: (Int) -> Void

    var body: some View {
        StepZone(amount: amount, perform: perform) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: .black))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: size, height: size)
                .background(Circle().fill(Color.white.opacity(0.14)))
        }
    }
}

/// Seat settings that stay the right way up for this player: colour, partner commanders,
/// and a way into renaming.
struct SeatSection: View {
    let player: Player
    let shortSide: CGFloat
    let onAccent: (String) -> Void
    let onCommanderCount: (Int) -> Void
    let onRename: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                spacing: 8
            ) {
                ForEach(Accent.all) { option in
                    Button {
                        Feedback.shared.select()
                        onAccent(option.id)
                    } label: {
                        Circle()
                            .fill(option.color)
                            .frame(height: min(max(shortSide * 0.14, 26), 42))
                            .overlay(
                                Circle().stroke(
                                    Color.white.opacity(player.accentID == option.id ? 0.95 : 0),
                                    lineWidth: 3
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                Button {
                    Feedback.shared.select()
                    onCommanderCount(player.commanderCount == 1 ? 2 : 1)
                } label: {
                    Label(
                        player.commanderCount == 1 ? "One commander" : "Partners",
                        systemImage: "crown.fill"
                    )
                    .font(.tally(min(max(shortSide * 0.06, 12), 15), weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)

                Button {
                    Feedback.shared.select()
                    onRename()
                } label: {
                    Label("Rename", systemImage: "pencil")
                        .font(.tally(min(max(shortSide * 0.06, 12), 15), weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)

                Button {
                    Feedback.shared.select()
                    onDone()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.black)
                        .padding(10)
                        .background(Circle().fill(Accent.named(player.accentID).color))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
