//
//  LegacyWindowBootstrap.swift
//  Reynard
//
//  Created by Codex on 15/6/26.
//

import UIKit

/// Installs the root window on iOS 12, where there is no scene support.
///
/// On iOS 13+ the system builds the app window from the `UIApplicationSceneManifest`
/// in Info.plist by instantiating `SceneDelegate`. On iOS 12 there are no scenes,
/// so the window has to be created from the application launch instead.
///
/// The catch: on device the real `UIApplication` delegate is Gecko's
/// `AppShellDelegate`, because libxul drives launch via
/// `UIApplicationMain(..., @"AppShellDelegate")` (see
/// `patches/widget/uikit/nsAppShell.mm.patch`). Reynard's own `AppDelegate` is
/// never installed as the delegate, so its `didFinishLaunchingWithOptions` never
/// runs and nothing builds the UI on iOS 12 — the screen stays black while the
/// Gecko run loop keeps the process alive.
///
/// We close that gap by listening for `UIApplication.didFinishLaunchingNotification`,
/// which the app receives regardless of which class is the delegate, and creating
/// the window there.
enum LegacyWindowBootstrap {
    private static var window: UIWindow?
    private static var launchObserver: NSObjectProtocol?

    /// The browser view controller hosting the iOS 12 window, if installed.
    static var rootBrowserViewController: BrowserViewController? {
        window?.rootViewController as? BrowserViewController
    }

    /// Registers the iOS 12 window installer. Must be called before
    /// `GeckoRuntime.main` (which never returns), i.e. before `UIApplicationMain`.
    static func installIfNeeded() {
        guard #unavailable(iOS 13.0) else {
            return
        }
        guard launchObserver == nil else {
            return
        }

        launchObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didFinishLaunchingNotification,
            object: nil,
            queue: .main
        ) { _ in
            installWindow()
        }
    }

    /// Creates and presents the root window if one is not already present.
    /// Idempotent and safe to call more than once.
    static func installWindow() {
        guard #unavailable(iOS 13.0) else {
            return
        }
        guard window == nil else {
            return
        }

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .reynardSystemBackground
        window.rootViewController = BrowserViewController()
        window.makeKeyAndVisible()
        self.window = window

        if let launchObserver {
            NotificationCenter.default.removeObserver(launchObserver)
            self.launchObserver = nil
        }
    }
}
