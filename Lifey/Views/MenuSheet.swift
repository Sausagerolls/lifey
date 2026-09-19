import SwiftUI

/// Mid-game controls: reset, rearrange, switch counter sections on or off, save the default.
struct MenuSheet: View {
    /// Handed back to `GameView`, which swaps this sheet for the dice sheet.
    var onRollDice: () -> Void = {}

    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmNewGame = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    Text("Table")
                        .font(.tally(26, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Theme.surfaceHigh))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)

                SectionCard(title: "Game") {
                    HStack(spacing: 10) {
                        SecondaryButton(title: "Reset totals", symbol: "arrow.counterclockwise") {
                            store.resetTotals()
                            dismiss()
                        }
                        SecondaryButton(title: "New game", symbol: "person.3.fill", tint: Color(hex: 0xFFB454)) {
                            confirmNewGame = true
                        }
                    }
                    SecondaryButton(title: "Dice and coin", symbol: "dice.fill", tint: Color(hex: 0x4CC9F0)) {
                        onRollDice()
                    }
                    Text("Hold the button in the middle of the table for the dice.")
                        .font(.tally(12, weight: .regular))
                        .foregroundStyle(Theme.textSecondary)
                }

                if SeatLayout.options(forPlayerCount: store.config.playerCount).count > 1 {
                    SectionCard(title: "Layout", subtitle: "Move the seats without ending the game") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(SeatLayout.options(forPlayerCount: store.config.playerCount)) { option in
                                    Button {
                                        Feedback.shared.select()
                                        store.config.layout = option
                                    } label: {
                                        VStack(spacing: 6) {
                                            LayoutPreview(layout: option, accentIDs: store.config.seatAccents)
                                                .frame(height: 78)
                                            Text(option.title)
                                                .font(.tally(13, weight: .bold))
                                                .foregroundStyle(Theme.textPrimary)
                                        }
                                        .frame(width: 130)
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Theme.surfaceHigh)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                        .stroke(
                                                            store.config.layout == option
                                                                ? Color(hex: 0x4CC9F0)
                                                                : Theme.hairline,
                                                            lineWidth: store.config.layout == option ? 2 : 1
                                                        )
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                SectionCard(title: "Counter sections") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                        ForEach(CounterKind.allCases) { kind in
                            SelectPill(
                                title: kind.title,
                                symbol: kind.symbol,
                                isSelected: store.config.enabledCounters.contains(kind),
                                tint: kind.tint
                            ) {
                                if let index = store.config.enabledCounters.firstIndex(of: kind) {
                                    store.config.enabledCounters.remove(at: index)
                                } else {
                                    store.config.enabledCounters.append(kind)
                                }
                            }
                        }
                    }

                    Text("YOUR OWN COUNTERS")
                        .font(.tally(12, weight: .heavy))
                        .tracking(1.4)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.top, 4)

                    CustomCounterSection()

                    SettingToggle(title: "Commander damage", isOn: $store.config.commanderDamageEnabled)
                    if store.config.commanderDamageEnabled {
                        SettingToggle(
                            title: "Commander damage takes life",
                            isOn: $store.config.commanderDamageAffectsLife
                        )
                    }
                }

                SectionCard(title: "Feel") {
                    SettingToggle(title: "Haptics", isOn: $store.config.hapticsEnabled)
                    SettingToggle(title: "Tap sound", isOn: $store.config.soundEnabled)
                    SettingToggle(title: "Keep screen awake", isOn: $store.config.keepScreenAwake)
                }

                SectionCard(title: "Default setup", subtitle: "Reopen Lifey with this exact table") {
                    PrimaryButton(
                        title: store.matchesSavedDefault ? "Saved as default" : "Save this setup as default",
                        symbol: store.matchesSavedDefault ? "checkmark.circle.fill" : "square.and.arrow.down.fill",
                        tint: store.matchesSavedDefault ? Color(hex: 0x3DDC97) : Color(hex: 0x4CC9F0)
                    ) {
                        store.saveAsDefault()
                    }

                    if store.savedDefault != nil {
                        SecondaryButton(title: "Forget default", symbol: "trash", tint: Theme.danger) {
                            store.clearDefault()
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.surface.ignoresSafeArea())
        .confirmationDialog(
            "Start a new game?",
            isPresented: $confirmNewGame,
            titleVisibility: .visible
        ) {
            Button("New game", role: .destructive) {
                store.returnToSetup()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears the current totals and returns to setup.")
        }
    }
}
