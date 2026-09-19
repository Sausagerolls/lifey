import AudioToolbox
import SwiftUI
import UIKit

/// Tactile and audible confirmation for taps, so players can keep their eyes on the board.
@MainActor
final class Feedback {
    static let shared = Feedback()

    var hapticsEnabled = true
    var soundEnabled = true

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notice = UINotificationFeedbackGenerator()

    private init() {}

    func prepare() {
        light.prepare()
        medium.prepare()
    }

    /// A single life or counter step.
    func step() {
        if hapticsEnabled { light.impactOccurred(intensity: 0.7) }
        if soundEnabled { AudioServicesPlaySystemSound(1104) }
    }

    /// Every fifth step during a hold, so long presses stay legible without buzzing constantly.
    func stepAccent() {
        if hapticsEnabled { rigid.impactOccurred(intensity: 0.9) }
        if soundEnabled { AudioServicesPlaySystemSound(1105) }
    }

    /// Mode changes, sheet openings, dice rolls.
    func select() {
        if hapticsEnabled { medium.impactOccurred(intensity: 0.6) }
    }

    /// A player crossing a lethal threshold.
    func lethal() {
        if hapticsEnabled { notice.notificationOccurred(.warning) }
        if soundEnabled { AudioServicesPlaySystemSound(1107) }
    }
}
