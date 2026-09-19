import SwiftUI

/// Everything a table decides before the first turn. Saved as the default with one tap.
struct SetupView: View {
    @EnvironmentObject private var store: GameStore
    @State private var selectedSeat = 0
    /// Held locally while typing. Writing straight through a binding republished the whole
    /// config on every keystroke, which snapped the field back to its old text.
    @State private var seatNameDraft = ""
    @FocusState private var nameFieldFocused: Bool

    private let lifePresets = [20, 25, 30, 40, 60]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                wordmark

                playersCard
                lifeCard
                layoutCard
                seatsCard
                countersCard
                feelCard

                PrimaryButton(title: "Start game", symbol: "play.fill") {
                    store.startGame()
                }

                SecondaryButton(
                    title: store.matchesSavedDefault ? "Saved as default" : "Save as default",
                    symbol: store.matchesSavedDefault ? "checkmark.circle.fill" : "square.and.arrow.down.fill",
                    tint: store.matchesSavedDefault ? Color(hex: 0x3DDC97) : Theme.textPrimary
                ) {
                    store.saveAsDefault()
                }

                // Kept small and set apart: it throws away the current setup.
                if store.savedDefault != nil, !store.matchesSavedDefault {
                    Button {
                        Feedback.shared.select()
                        store.loadSavedDefault()
                        selectedSeat = min(selectedSeat, store.config.playerCount - 1)
                        seatNameDraft = store.config.name(forSeat: selectedSeat)
                    } label: {
                        Text("Discard changes and load saved default")
                            .font(.tally(13, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }

                Text("The default remembers seats, colours, life total, layout and every counter section you switched on.")
                    .font(.tally(12, weight: .regular))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background.ignoresSafeArea())
        .onAppear { OrientationController.unlock() }
    }

    // MARK: - Header

    private var wordmark: some View {
        VStack(spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: "suit.heart.fill")
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: 0xFF4D6D), Color(hex: 0xB388FF)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("Lifey")
                    .font(.tally(40, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
            }
            Text("Life, commander damage and counters")
                .font(.tally(13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Cards

    private var playersCard: some View {
        SectionCard(title: "Players") {
            HStack(spacing: 8) {
                ForEach(2...4, id: \.self) { count in
                    SelectPill(title: "\(count)", isSelected: store.config.playerCount == count) {
                        store.config.playerCount = count
                        store.config.normalize()
                        selectedSeat = min(selectedSeat, count - 1)
                        seatNameDraft = store.config.name(forSeat: selectedSeat)
                    }
                }
            }
            Text(store.config.playerCount == 2
                 ? "Portrait. Stand the phone between both players."
                 : "Landscape. Choose a seat for each player below.")
                .font(.tally(12, weight: .regular))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var lifeCard: some View {
        SectionCard(title: "Starting life") {
            HStack(spacing: 8) {
                ForEach(lifePresets, id: \.self) { value in
                    SelectPill(
                        title: "\(value)",
                        isSelected: store.config.startingLife == value,
                        tint: Color(hex: 0xFFB454)
                    ) {
                        store.config.startingLife = value
                    }
                }
            }

            HStack(spacing: 10) {
                stepButton("minus", amount: -1)
                Text("\(store.config.startingLife)")
                    .font(.tally(34, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity)
                stepButton("plus", amount: 1)
            }
        }
    }

    private func stepButton(_ symbol: String, amount: Int) -> some View {
        Button {
            Feedback.shared.step()
            store.config.startingLife = max(1, store.config.startingLife + amount)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 46, height: 46)
                .background(Circle().fill(Theme.surfaceHigh))
        }
        .buttonStyle(.plain)
    }

    private var layoutCard: some View {
        SectionCard(title: "Table layout", subtitle: SeatLayout.options(forPlayerCount: store.config.playerCount).count > 1 ? "Pick how the seats sit on screen" : nil) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SeatLayout.options(forPlayerCount: store.config.playerCount)) { option in
                        Button {
                            Feedback.shared.select()
                            store.config.layout = option
                        } label: {
                            VStack(spacing: 8) {
                                LayoutPreview(layout: option, accentIDs: store.config.seatAccents)
                                    .frame(height: 92)
                                Text(option.title)
                                    .font(.tally(14, weight: .bold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(option.subtitle)
                                    .font(.tally(11, weight: .regular))
                                    .foregroundStyle(Theme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(width: 150)
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
                .padding(.horizontal, 1)
            }
        }
    }

    private var seatsCard: some View {
        SectionCard(title: "Seats", subtitle: "Tap a seat to name it and pick its colour") {
            SeatPicker(
                layout: store.config.layout,
                accentIDs: store.config.seatAccents,
                selectedSeat: $selectedSeat
            )
            .frame(height: store.config.layout.orientation == .portrait ? 220 : 150)

            TextField("Player name", text: $seatNameDraft)
                .textFieldStyle(.plain)
                .font(.tally(20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surfaceHigh))
                .focused($nameFieldFocused)
                .submitLabel(.done)
                .onChange(of: seatNameDraft) { _, value in
                    commitSeatName(value)
                }
                .onChange(of: selectedSeat) { _, seat in
                    seatNameDraft = store.config.name(forSeat: seat)
                }
                .onAppear { seatNameDraft = store.config.name(forSeat: selectedSeat) }

            HStack(spacing: 8) {
                ForEach(Accent.all) { accent in
                    Button {
                        Feedback.shared.select()
                        store.config.seatAccents[selectedSeat] = accent.id
                    } label: {
                        Circle()
                            .fill(accent.color)
                            .frame(height: 34)
                            .overlay(
                                Circle().stroke(
                                    .white.opacity(store.config.accentID(forSeat: selectedSeat) == accent.id ? 0.95 : 0),
                                    lineWidth: 3
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Stores the typed name against the selected seat, leaving the rest of the config alone.
    private func commitSeatName(_ name: String) {
        guard selectedSeat < store.config.seatNames.count else { return }
        guard store.config.seatNames[selectedSeat] != name else { return }
        store.config.seatNames[selectedSeat] = name
    }

    private var countersCard: some View {
        SectionCard(title: "Counter sections", subtitle: "Shown as chips on every panel") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(CounterKind.allCases) { kind in
                    SelectPill(
                        title: kind.title,
                        symbol: kind.symbol,
                        isSelected: store.config.enabledCounters.contains(kind),
                        tint: kind.tint
                    ) {
                        toggle(kind)
                    }
                }
            }

            Text("YOUR OWN COUNTERS")
                .font(.tally(12, weight: .heavy))
                .tracking(1.4)
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, 4)

            CustomCounterSection()

            SettingToggle(
                title: "Commander damage",
                subtitle: "Each panel tracks what its own commanders deal, 21 is lethal",
                isOn: $store.config.commanderDamageEnabled
            )

            if store.config.commanderDamageEnabled {
                SettingToggle(
                    title: "Commander damage takes life",
                    subtitle: "Dealing 5 commander damage takes 5 life off that opponent",
                    isOn: $store.config.commanderDamageAffectsLife
                )
                SettingToggle(
                    title: "Partner commanders",
                    subtitle: "A tile per commander against each opponent",
                    isOn: $store.config.partnerCommanders
                )
            }
        }
    }

    private var feelCard: some View {
        SectionCard(title: "Feel") {
            SettingToggle(title: "Haptics", isOn: $store.config.hapticsEnabled)
            SettingToggle(title: "Tap sound", isOn: $store.config.soundEnabled)
            SettingToggle(
                title: "Keep screen awake",
                subtitle: "Stops the phone sleeping mid game",
                isOn: $store.config.keepScreenAwake
            )
        }
    }

    private func toggle(_ kind: CounterKind) {
        if let index = store.config.enabledCounters.firstIndex(of: kind) {
            store.config.enabledCounters.remove(at: index)
        } else {
            store.config.enabledCounters.append(kind)
            store.config.enabledCounters.sort {
                (CounterKind.allCases.firstIndex(of: $0) ?? 0) < (CounterKind.allCases.firstIndex(of: $1) ?? 0)
            }
        }
    }
}

/// The layout diagram, with each seat tappable.
private struct SeatPicker: View {
    let layout: SeatLayout
    let accentIDs: [String]
    @Binding var selectedSeat: Int

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LayoutPreview(layout: layout, accentIDs: accentIDs, highlightedSeat: selectedSeat)
                    .frame(width: geo.size.width, height: geo.size.height)

                ForEach(layout.slots) { slot in
                    let frame = previewFrame(for: slot, in: geo.size)
                    Color.white.opacity(0.001)
                        .frame(width: max(frame.width, 1), height: max(frame.height, 1))
                        .position(x: frame.midX, y: frame.midY)
                        .onTapGesture {
                            Feedback.shared.select()
                            selectedSeat = slot.id
                        }
                }
            }
        }
    }

    /// Matches the box `LayoutPreview` fits itself into, so the hit areas line up.
    private func previewFrame(for slot: SeatSlot, in size: CGSize) -> CGRect {
        let ratio: CGFloat = layout.orientation == .portrait ? 0.62 : 1.55
        var width = size.width
        var height = width / ratio
        if height > size.height {
            height = size.height
            width = height * ratio
        }
        let originX = (size.width - width) / 2
        let originY = (size.height - height) / 2
        return CGRect(
            x: originX + slot.rect.minX * width,
            y: originY + slot.rect.minY * height,
            width: slot.rect.width * width,
            height: slot.rect.height * height
        )
    }
}
