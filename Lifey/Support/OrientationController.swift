import SwiftUI
import UIKit

/// Two players share a phone stood between them in portrait; three or four need the
/// extra width of landscape. Lifey drives the device orientation to match the layout.
final class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationMask: UIInterfaceOrientationMask = .all

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        AppDelegate.orientationMask
    }
}

enum OrientationController {
    @MainActor
    static func lock(to orientation: ScreenOrientation) {
        apply(orientation == .portrait ? .portrait : .landscape)
    }

    @MainActor
    static func unlock() {
        apply(.all)
    }

    @MainActor
    private static func apply(_ mask: UIInterfaceOrientationMask) {
        AppDelegate.orientationMask = mask
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return }
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
        scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}
