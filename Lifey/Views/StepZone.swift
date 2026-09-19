import SwiftUI

/// A large press target that fires once on touch and then repeats, faster the longer
/// it is held, so a 17 point swing is one press rather than seventeen taps.
struct StepZone<Label: View>: View {
    let amount: Int
    let perform: (Int) -> Void
    @ViewBuilder var label: () -> Label

    @State private var isPressed = false
    @State private var repeater: Task<Void, Never>?
    @State private var firedCount = 0

    var body: some View {
        label()
            .contentShape(Rectangle())
            .opacity(isPressed ? 0.55 : 1)
            .animation(.easeOut(duration: 0.12), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in begin() }
                    .onEnded { _ in end() }
            )
            .onDisappear { end() }
    }

    private func begin() {
        guard !isPressed else { return }
        isPressed = true
        firedCount = 0
        fire()
        repeater = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(420))
            var interval = 170
            while !Task.isCancelled, isPressed {
                fire()
                try? await Task.sleep(for: .milliseconds(interval))
                interval = max(55, interval - 12)
            }
        }
    }

    private func fire() {
        firedCount += 1
        perform(amount)
        if firedCount % 5 == 0 {
            Feedback.shared.stepAccent()
        } else {
            Feedback.shared.step()
        }
    }

    private func end() {
        isPressed = false
        repeater?.cancel()
        repeater = nil
    }
}
