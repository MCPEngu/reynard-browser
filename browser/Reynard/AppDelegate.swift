//
//  AppDelegate.swift
//  Reynard
//
//  Created by Minh Ton on 1/2/26.
//

import UIKit

// NOTE: On device this class is NOT installed as the UIApplication delegate —
// libxul launches via `UIApplicationMain(..., @"AppShellDelegate")`, so these
// callbacks do not fire. iOS 12 window creation is driven from
// `LegacyWindowBootstrap` (wired in `main.swift`); the iOS 13+ window comes from
// `SceneDelegate` via the Info.plist scene manifest. This type is kept for
// completeness and routes through the shared bootstrap to avoid divergence.
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        LegacyWindowBootstrap.installWindow()
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let browserViewController = LegacyWindowBootstrap.rootBrowserViewController,
              let resolvedURL = BrowserURLResolver.resolvedBrowserURL(from: url) else {
            return false
        }
        
        DispatchQueue.main.async {
            browserViewController.openExternalURL(resolvedURL)
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
