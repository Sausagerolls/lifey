import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch store.phase {
            case .setup:
                SetupView()
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            case .playing:
                GameView()
                    .transition(.opacity.combined(with: .scale(scale: 1.03)))
            }
        }
        .animation(.smooth(duration: 0.35), value: store.phase)
    }
}
