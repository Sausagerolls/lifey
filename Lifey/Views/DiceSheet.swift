import SwiftUI

/// Coin, dice and a random first player, so nobody hunts for a spare die.
struct DiceSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    @State private var resultText = "—"
    @State private var resultDetail = "Pick a roll"
    @State private var resultTint = Theme.textPrimary
    @State private var rolling = false

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Roll")
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

            VStack(spacing: 4) {
                Text(resultText)
                    .font(.tally(72, weight: .heavy))
                    .foregroundStyle(resultTint)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .scaleEffect(rolling ? 0.9 : 1)
                    .animation(.snappy(duration: 0.2), value: resultText)
                Text(resultDetail)
                    .font(.tally(14, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 130)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.surfaceHigh)
            )

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                rollButton("Coin flip", symbol: "circle.lefthalf.filled", tint: Color(hex: 0xFFB454)) {
                    let heads = Bool.random()
                    return (heads ? "Heads" : "Tails", "Coin flip", Color(hex: 0xFFB454))
                }
                rollButton("D20", symbol: "die.face.5.fill", tint: Color(hex: 0x4CC9F0)) {
                    let value = Int.random(in: 1...20)
                    return ("\(value)", "D20", value == 20 ? Color(hex: 0x3DDC97) : (value == 1 ? Theme.danger : Color(hex: 0x4CC9F0)))
                }
                rollButton("D6", symbol: "die.face.6.fill", tint: Color(hex: 0xB388FF)) {
                    ("\(Int.random(in: 1...6))", "D6", Color(hex: 0xB388FF))
                }
                rollButton("Who starts", symbol: "person.fill.questionmark", tint: Color(hex: 0x3DDC97)) {
                    guard let player = store.players.randomElement() else {
                        return ("—", "No players", Theme.textPrimary)
                    }
                    return (player.name, "Goes first", Accent.named(player.accentID).color)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Theme.surface.ignoresSafeArea())
    }

    private func rollButton(
        _ title: String,
        symbol: String,
        tint: Color,
        roll: @escaping () -> (String, String, Color)
    ) -> some View {
        Button {
            Feedback.shared.select()
            rolling = true
            let outcome = roll()
            withAnimation(.snappy(duration: 0.2)) {
                resultText = outcome.0
                resultDetail = outcome.1
                resultTint = outcome.2
                rolling = false
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .bold))
                Text(title)
                    .font(.tally(17, weight: .bold))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surfaceHigh)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(tint.opacity(0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
