import SwiftUI

/// Visual language for Lifey: a dark slate stage with one saturated accent per player.
enum Theme {
    static let background = Color(hex: 0x0A0C12)
    static let surface = Color(hex: 0x141926)
    static let surfaceHigh = Color(hex: 0x1D2333)
    static let hairline = Color.white.opacity(0.08)
    static let textPrimary = Color(hex: 0xF2F5FA)
    static let textSecondary = Color(hex: 0x8D9AB4)
    static let danger = Color(hex: 0xFF4D4D)

    static let panelCorner: CGFloat = 26

    /// Type and controls are sized from the panel's short side, but the ceilings that keep
    /// a phone panel sensible leave a tablet panel looking half empty. Panels wider than
    /// this are given the roomier ceiling.
    static let tabletPanelThreshold: CGFloat = 560

    static func cap(_ shortSide: CGFloat, phone: CGFloat, tablet: CGFloat) -> CGFloat {
        shortSide < tabletPanelThreshold ? phone : tablet
    }
}

/// One of the selectable player accents. Stored by `id` so presets survive app updates.
struct Accent: Identifiable, Hashable {
    let id: String
    let name: String
    let color: Color

    static let all: [Accent] = [
        Accent(id: "crimson", name: "Crimson", color: Color(hex: 0xFF4D6D)),
        Accent(id: "azure", name: "Azure", color: Color(hex: 0x4CC9F0)),
        Accent(id: "emerald", name: "Emerald", color: Color(hex: 0x3DDC97)),
        Accent(id: "amber", name: "Amber", color: Color(hex: 0xFFB454)),
        Accent(id: "violet", name: "Violet", color: Color(hex: 0xB388FF)),
        Accent(id: "rose", name: "Rose", color: Color(hex: 0xFF7AB6)),
        Accent(id: "lime", name: "Lime", color: Color(hex: 0xC8F04D)),
        Accent(id: "steel", name: "Steel", color: Color(hex: 0xA8B8D8)),
    ]

    static func named(_ id: String) -> Accent {
        all.first { $0.id == id } ?? all[0]
    }

    /// Default accent for a seat, wrapping if there are more seats than accents.
    static func forSeat(_ index: Int) -> Accent {
        all[index % all.count]
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

extension Font {
    /// Rounded numerals are easier to read across a table at a glance.
    static func tally(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
