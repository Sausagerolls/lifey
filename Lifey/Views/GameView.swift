import SwiftUI

/// The table itself: one panel per seat, each rotated to face its player.
struct GameView: View {
    @EnvironmentObject private var store: GameStore
    @State private var showMenu = false
    @State private var showDice = false

    private let gap: CGFloat = 5

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(store.config.layout.slots) { slot in
                    if let player = store.player(at: slot.id) {
                        panel(for: player, slot: slot, in: geo.size)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .overlay(alignment: .center) {
                CenterMenuButton(
                    onMenu: {
                        Feedback.shared.select()
                        showMenu = true
                    },
                    onDice: {
                        Feedback.shared.select()
                        showDice = true
                    }
                )
            }
        }
        .padding(gap)
        .background(Theme.background.ignoresSafeArea())
        .onAppear { OrientationController.lock(to: store.config.layout.orientation) }
        .onChange(of: store.config.layout) { _, layout in
            OrientationController.lock(to: layout.orientation)
        }
        .sheet(isPresented: $showMenu) {
            MenuSheet(onRollDice: {
                showMenu = false
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(350))
                    showDice = true
                }
            })
                .environmentObject(store)
                .presentationDetents([.medium, .large])
                .presentationBackground(Theme.surface)
        }
        .sheet(isPresented: $showDice) {
            DiceSheet()
                .environmentObject(store)
                .presentationDetents([.medium])
                .presentationBackground(Theme.surface)
        }
    }

    @ViewBuilder
    private func panel(for player: Player, slot: SeatSlot, in size: CGSize) -> some View {
        let frame = CGRect(
            x: slot.rect.minX * size.width,
            y: slot.rect.minY * size.height,
            width: slot.rect.width * size.width,
            height: slot.rect.height * size.height
        ).insetBy(dx: gap, dy: gap)

        // A panel turned on its side is laid out with its width and height swapped,
        // then rotated into place.
        let sideways = abs(slot.rotation) == 90
        let panelSize = sideways
            ? CGSize(width: frame.height, height: frame.width)
            : CGSize(width: frame.width, height: frame.height)

        PlayerPanel(player: player, seat: slot.id)
            .frame(width: max(panelSize.width, 1), height: max(panelSize.height, 1))
            .rotationEffect(.degrees(slot.rotation))
            .position(x: frame.midX, y: frame.midY)
    }
}

/// The only chrome on the table: one small hub where the panels meet. Tapping opens the
/// table menu, holding jumps straight to the dice.
private struct CenterMenuButton: View {
    let onMenu: () -> Void
    let onDice: () -> Void

    var body: some View {
        Button(action: onMenu) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Theme.surfaceHigh.opacity(0.96))
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                        .shadow(color: .black.opacity(0.6), radius: 12, y: 3)
                )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4).onEnded { _ in onDice() }
        )
    }
}
