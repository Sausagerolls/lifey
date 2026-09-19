import SwiftUI

/// A small diagram of a table arrangement. Each seat is drawn in its player's colour,
/// with the seat number turned the way that player will read it.
struct LayoutPreview: View {
    let layout: SeatLayout
    let accentIDs: [String]
    var highlightedSeat: Int? = nil
    var showsNumbers: Bool = true

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(layout.slots) { slot in
                    let frame = CGRect(
                        x: slot.rect.minX * geo.size.width,
                        y: slot.rect.minY * geo.size.height,
                        width: slot.rect.width * geo.size.width,
                        height: slot.rect.height * geo.size.height
                    ).insetBy(dx: 2, dy: 2)
                    let color = Accent.named(accentID(for: slot.id)).color
                    let isHighlighted = highlightedSeat == slot.id

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(color.opacity(isHighlighted ? 0.95 : 0.55))
                        .overlay {
                            if showsNumbers {
                                Text("\(slot.id + 1)")
                                    .font(.tally(min(frame.height, frame.width) * 0.45, weight: .heavy))
                                    .foregroundStyle(.black.opacity(0.75))
                                    .rotationEffect(.degrees(slot.rotation))
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(.white.opacity(isHighlighted ? 0.9 : 0.15), lineWidth: isHighlighted ? 2 : 1)
                        }
                        .frame(width: max(frame.width, 1), height: max(frame.height, 1))
                        .position(x: frame.midX, y: frame.midY)
                }
            }
        }
        .aspectRatio(layout.orientation == .portrait ? 0.62 : 1.55, contentMode: .fit)
    }

    private func accentID(for seat: Int) -> String {
        seat < accentIDs.count ? accentIDs[seat] : Accent.forSeat(seat).id
    }
}
