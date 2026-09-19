import SwiftUI

enum PanelMode: Equatable {
    case life
    /// Carries a `CounterDefinition` id, so built-in and custom counters both fit.
    case counter(String)
    case commander
    case seat
}

/// One player's whole world: life in the middle, counters along the bottom, and a
/// commander damage section a single tap away. The panel never rotates its own content,
/// the table layout rotates the panel.
struct PlayerPanel: View {
    let player: Player
    let seat: Int

    @EnvironmentObject private var store: GameStore
    @State private var mode: PanelMode = .life
    @State private var delta = 0
    @State private var deltaReset: Task<Void, Never>?
    @State private var showRename = false
    @State private var draftName = ""

    private var accent: Accent { Accent.named(player.accentID) }

    var body: some View {
        GeometryReader { geo in
            let shortSide = min(geo.size.width, geo.size.height)
            let pad = min(max(shortSide * 0.055, 8), 16)

            ZStack {
                panelBackground

                VStack(spacing: pad * 0.4) {
                    header(shortSide: shortSide)
                    content(size: geo.size, shortSide: shortSide)
                    footer(shortSide: shortSide, width: geo.size.width)
                }
                .padding(pad)
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous))
            .overlay {
                if player.isEliminated {
                    RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
                        .stroke(Theme.danger.opacity(0.85), lineWidth: 2.5)
                        .allowsHitTesting(false)
                }
            }
        }
        .sheet(isPresented: $showRename) {
            RenameSheet(name: $draftName) { newName in
                store.rename(playerID: player.id, to: newName)
            }
            .presentationDetents([.height(220)])
            .presentationBackground(Theme.surface)
        }
    }

    // MARK: - Background

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
            .fill(Theme.surface)
            .overlay {
                RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accent.color.opacity(0.34), accent.color.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
                    .stroke(accent.color.opacity(0.5), lineWidth: 1.5)
            }
            .shadow(color: accent.color.opacity(0.22), radius: 18, y: 6)
    }

    // MARK: - Header

    private func header(shortSide: CGFloat) -> some View {
        HStack(spacing: 8) {
            Button {
                Feedback.shared.select()
                withAnimation(.snappy(duration: 0.2)) {
                    mode = mode == .seat ? .life : .seat
                }
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(accent.color)
                        .frame(width: 10, height: 10)
                    Text(player.name)
                        .font(.tally(min(max(shortSide * 0.085, 13), 20), weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 4)

            if player.isEliminated {
                Label("OUT", systemImage: "xmark.octagon.fill")
                    .font(.tally(min(max(shortSide * 0.07, 11), 15), weight: .heavy))
                    .foregroundStyle(Theme.danger)
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(size: CGSize, shortSide: CGFloat) -> some View {
        switch mode {
        case .life:
            lifeTally(shortSide: shortSide)
        case .counter(let counterID):
            if let definition = store.config.counterDefinitions.first(where: { $0.id == counterID }) {
                tallyArea(
                    value: player.counter(id: counterID),
                    tint: definition.tint,
                    shortSide: shortSide,
                    caption: definition.title.uppercased(),
                    warn: definition.lethalThreshold.map { player.counter(id: counterID) >= $0 } ?? false,
                    step: { store.adjustCounter(playerID: player.id, counterID: counterID, by: $0) }
                )
            } else {
                // The counter was deleted while this panel was showing it.
                lifeTally(shortSide: shortSide)
            }
        case .commander:
            CommanderSection(player: player, accent: accent, shortSide: shortSide) { opponentID, commanderIndex, amount in
                // This panel's commander is the attacker, so the life comes off the opponent.
                store.adjustCommanderDamage(
                    targetID: opponentID,
                    sourceID: player.id,
                    commanderIndex: commanderIndex,
                    by: amount
                )
            }
        case .seat:
            SeatSection(
                player: player,
                shortSide: shortSide,
                onAccent: { store.setAccent(playerID: player.id, accentID: $0) },
                onCommanderCount: { store.setCommanderCount(playerID: player.id, to: $0) },
                onRename: {
                    draftName = player.name
                    showRename = true
                },
                onDone: { withAnimation(.snappy(duration: 0.2)) { mode = .life } }
            )
        }
    }

    private func lifeTally(shortSide: CGFloat) -> some View {
        tallyArea(
            value: player.life,
            tint: Theme.textPrimary,
            shortSide: shortSide,
            step: { applyLife($0) }
        )
    }

    /// The big number with a minus half and a plus half behind it.
    private func tallyArea(
        value: Int,
        tint: Color,
        shortSide: CGFloat,
        caption: String? = nil,
        warn: Bool = false,
        step: @escaping (Int) -> Void
    ) -> some View {
        ZStack {
            HStack(spacing: 0) {
                StepZone(amount: -1, perform: step) {
                    stepGlyph("minus")
                }
                StepZone(amount: 1, perform: step) {
                    stepGlyph("plus")
                }
            }

            VStack(spacing: 0) {
                if let caption {
                    Text(caption)
                        .font(.tally(min(max(shortSide * 0.075, 11), 17), weight: .heavy))
                        .foregroundStyle(tint.opacity(0.9))
                        .tracking(2)
                }

                Text("\(value)")
                    .font(.tally(min(max(shortSide * 0.46, 54), 190), weight: .heavy))
                    .foregroundStyle(warn ? Theme.danger : tint)
                    .monospacedDigit()
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .contentTransition(.numericText(value: Double(value)))
                    .animation(.snappy(duration: 0.18), value: value)
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
            }
            .allowsHitTesting(false)

            if delta != 0 {
                Text(delta > 0 ? "+\(delta)" : "\(delta)")
                    .font(.tally(min(max(shortSide * 0.1, 15), 26), weight: .bold))
                    .foregroundStyle(delta > 0 ? Color(hex: 0x6EE7A8) : Theme.danger)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.35)))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .allowsHitTesting(false)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func stepGlyph(_ symbol: String) -> some View {
        ZStack {
            Color.white.opacity(0.001)
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(Color.white.opacity(0.28))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: symbol == "minus" ? .leading : .trailing)
                .padding(.horizontal, 10)
        }
    }

    // MARK: - Footer

    private func footer(shortSide: CGFloat, width: CGFloat) -> some View {
        let chips = chipSpecs
        // A compact chip needs roughly 70 points; anything past that scrolls instead.
        let fitsInRow = CGFloat(chips.count) * 70 <= width
        return Group {
            if fitsInRow {
                // Everything fits, so spread the chips across the full width.
                // Spread the chips, but never so far apart that they stop reading as a row.
                HStack(spacing: 6) {
                    ForEach(chips) { chip in
                        chipView(chip, shortSide: shortSide, compact: CGFloat(chips.count) * 108 > width)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: min(width, CGFloat(chips.count) * 118))
                .frame(maxWidth: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(chips) { chip in
                            chipView(chip, shortSide: shortSide, compact: true)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .frame(height: min(max(shortSide * 0.17, 36), 52))
    }

    private struct ChipSpec: Identifiable {
        let id: String
        let title: String
        let symbol: String
        let value: Int
        let tint: Color
        let isActive: Bool
        let warn: Bool
        let mode: PanelMode
    }

    private var chipSpecs: [ChipSpec] {
        var specs: [ChipSpec] = []

        if store.config.commanderDamageEnabled, store.players.count > 1 {
            // The chip counts the heaviest hit this player's own commanders have landed.
            let worstDealt = store.worstCommanderDamageDealt(by: player.id)
            specs.append(
                ChipSpec(
                    id: "cmd",
                    title: "CMD",
                    symbol: "crown.fill",
                    value: worstDealt,
                    tint: Color(hex: 0xFFD166),
                    isActive: mode == .commander,
                    warn: worstDealt >= 21,
                    mode: .commander
                )
            )
        }

        for definition in store.config.counterDefinitions {
            let value = player.counter(id: definition.id)
            specs.append(
                ChipSpec(
                    id: definition.id,
                    title: definition.abbreviation,
                    symbol: definition.symbol,
                    value: value,
                    tint: definition.tint,
                    isActive: mode == .counter(definition.id),
                    warn: definition.lethalThreshold.map { value >= $0 } ?? false,
                    mode: .counter(definition.id)
                )
            )
        }

        if mode != .life {
            specs.append(
                ChipSpec(
                    id: "life",
                    title: "LIFE",
                    symbol: "heart.fill",
                    value: player.life,
                    tint: accent.color,
                    isActive: false,
                    warn: false,
                    mode: .life
                )
            )
        }

        return specs
    }

    private func chipView(_ chip: ChipSpec, shortSide: CGFloat, compact: Bool) -> some View {
        PanelChip(
            title: chip.title,
            symbol: chip.symbol,
            value: chip.value,
            tint: chip.tint,
            isActive: chip.isActive,
            warn: chip.warn,
            shortSide: shortSide,
            showsTitle: !compact
        ) {
            Feedback.shared.select()
            withAnimation(.snappy(duration: 0.2)) {
                mode = mode == chip.mode ? .life : chip.mode
            }
        }
    }

    // MARK: - Actions

    private func applyLife(_ amount: Int) {
        store.adjustLife(playerID: player.id, by: amount)
        bumpDelta(amount)
    }

    /// Shows a running total of the current exchange, then clears itself.
    private func bumpDelta(_ amount: Int) {
        withAnimation(.snappy(duration: 0.15)) { delta += amount }
        deltaReset?.cancel()
        deltaReset = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) { delta = 0 }
        }
    }
}

/// A counter shortcut along the bottom of a panel.
private struct PanelChip: View {
    let title: String
    let symbol: String
    let value: Int
    let tint: Color
    let isActive: Bool
    let warn: Bool
    let shortSide: CGFloat
    var showsTitle: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: min(max(shortSide * 0.055, 11), 15), weight: .bold))
                Text("\(value)")
                    .font(.tally(min(max(shortSide * 0.075, 14), 19), weight: .heavy))
                    .monospacedDigit()
                if showsTitle {
                    Text(title)
                        .font(.tally(min(max(shortSide * 0.05, 9), 12), weight: .semibold))
                        .opacity(0.75)
                        .lineLimit(1)
                }
            }
            .foregroundStyle(warn ? Theme.danger : (isActive ? Color.black : tint))
            .padding(.horizontal, showsTitle ? 10 : 8)
            .frame(maxHeight: .infinity)
            .background(
                Capsule(style: .continuous)
                    .fill(isActive ? tint : Color.black.opacity(0.28))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(warn ? Theme.danger : tint.opacity(isActive ? 0 : 0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct RenameSheet: View {
    @Binding var name: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Text("Player name")
                .font(.tally(18, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            TextField("Name", text: $name)
                .textFieldStyle(.plain)
                .font(.tally(22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surfaceHigh))
                .submitLabel(.done)
                .onSubmit { save() }

            Button("Save") { save() }
                .font(.tally(18, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.12)))
                .foregroundStyle(Theme.textPrimary)
                .buttonStyle(.plain)
        }
        .padding(20)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(trimmed.isEmpty ? "Player" : trimmed)
        dismiss()
    }
}
