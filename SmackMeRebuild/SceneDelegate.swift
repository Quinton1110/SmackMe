//
//  SceneDelegate.swift
//  SmackMe
//
//  Scene delegate for iOS 13+ multi-window support
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)

        let mainMenuVC = MainMenuViewController()
        let navigationController = UINavigationController(rootViewController: mainMenuVC)

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called when the scene is released by the system
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Resume audio when returning from Notification Center, Control Center,
        // or any other interruption that triggers sceneWillResignActive.
        // sceneWillEnterForeground only fires for full background→foreground,
        // but sceneDidBecomeActive covers ALL cases including partial overlays.
        AudioManager.shared.resumeMusic()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Pause audio when app goes to background
        AudioManager.shared.pauseMusic()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Audio resume is handled in sceneDidBecomeActive (covers both
        // full background return AND Notification Center / Control Center)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save any state if needed
    }
}
