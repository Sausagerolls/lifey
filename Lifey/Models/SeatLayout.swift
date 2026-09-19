import CoreGraphics
import Foundation

/// A place at the table: where the panel sits on screen and which way it faces.
struct SeatSlot: Identifiable {
    let id: Int
    /// Position and size in unit coordinates, 0...1 across the screen.
    let rect: CGRect
    /// Clockwise rotation in degrees. 0 faces the player sitting at the bottom edge.
    let rotation: Double
}

enum ScreenOrientation {
    case portrait
    case landscape
}

/// The table arrangements Lifey can draw. Two players sit head to head in portrait;
/// three and four players get landscape arrangements so nobody reads sideways by accident.
enum SeatLayout: String, CaseIterable, Identifiable, Codable {
    case duel
    case duelSide
    case triTop
    case triBottom
    case triPinwheel
    case quadGrid
    case quadPinwheel

    var id: String { rawValue }

    var playerCount: Int {
        switch self {
        case .duel, .duelSide: return 2
        case .triTop, .triBottom, .triPinwheel: return 3
        case .quadGrid, .quadPinwheel: return 4
        }
    }

    var orientation: ScreenOrientation {
        switch self {
        case .duel: return .portrait
        default: return .landscape
        }
    }

    var title: String {
        switch self {
        case .duel: return "Head to Head"
        case .duelSide: return "Side by Side"
        case .triTop: return "One Across"
        case .triBottom: return "Two Across"
        case .triPinwheel: return "Three Corner"
        case .quadGrid: return "Quad Grid"
        case .quadPinwheel: return "Pinwheel"
        }
    }

    var subtitle: String {
        switch self {
        case .duel: return "Portrait, phone between both players"
        case .duelSide: return "Landscape, one player each side"
        case .triTop: return "One player across the top"
        case .triBottom: return "Two players across the top"
        case .triPinwheel: return "One side seat, two stacked"
        case .quadGrid: return "Two facing two"
        case .quadPinwheel: return "Four seats, one per edge"
        }
    }

    var slots: [SeatSlot] {
        switch self {
        case .duel:
            return [
                SeatSlot(id: 0, rect: CGRect(x: 0, y: 0, width: 1, height: 0.5), rotation: 180),
                SeatSlot(id: 1, rect: CGRect(x: 0, y: 0.5, width: 1, height: 0.5), rotation: 0),
            ]
        case .duelSide:
            return [
                SeatSlot(id: 0, rect: CGRect(x: 0, y: 0, width: 0.5, height: 1), rotation: 90),
                SeatSlot(id: 1, rect: CGRect(x: 0.5, y: 0, width: 0.5, height: 1), rotation: -90),
            ]
        case .triTop:
            return [
                SeatSlot(id: 0, rect: CGRect(x: 0, y: 0, width: 1, height: 0.5), rotation: 180),
                SeatSlot(id: 1, rect: CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5), rotation: 0),
                SeatSlot(id: 2, rect: CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5), rotation: 0),
            ]
        case .triBottom:
            return [
                SeatSlot(id: 0, rect: CGRect(x: 0, y: 0, width: 0.5, height: 0.5), rotation: 180),
                SeatSlot(id: 1, rect: CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5), rotation: 180),
                SeatSlot(id: 2, rect: CGRect(x: 0, y: 0.5, width: 1, height: 0.5), rotation: 0),
            ]
        case .triPinwheel:
            return [
                SeatSlot(id: 0, rect: CGRect(x: 0, y: 0, width: 0.34, height: 1), rotation: 90),
                SeatSlot(id: 1, rect: CGRect(x: 0.34, y: 0, width: 0.66, height: 0.5), rotation: 180),
                SeatSlot(id: 2, rect: CGRect(x: 0.34, y: 0.5, width: 0.66, height: 0.5), rotation: 0),
            ]
        case .quadGrid:
            return [
                SeatSlot(id: 0, rect: CGRect(x: 0, y: 0, width: 0.5, height: 0.5), rotation: 180),
                SeatSlot(id: 1, rect: CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5), rotation: 180),
                SeatSlot(id: 2, rect: CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5), rotation: 0),
                SeatSlot(id: 3, rect: CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5), rotation: 0),
            ]
        case .quadPinwheel:
            return [
                SeatSlot(id: 0, rect: CGRect(x: 0, y: 0, width: 0.26, height: 1), rotation: 90),
                SeatSlot(id: 1, rect: CGRect(x: 0.26, y: 0, width: 0.48, height: 0.5), rotation: 180),
                SeatSlot(id: 2, rect: CGRect(x: 0.74, y: 0, width: 0.26, height: 1), rotation: -90),
                SeatSlot(id: 3, rect: CGRect(x: 0.26, y: 0.5, width: 0.48, height: 0.5), rotation: 0),
            ]
        }
    }

    static func options(forPlayerCount count: Int) -> [SeatLayout] {
        allCases.filter { $0.playerCount == count }
    }

    static func first(forPlayerCount count: Int) -> SeatLayout {
        options(forPlayerCount: count).first ?? .duel
    }
}
