//
//  SceneDelegate.swift
//  CryptoLaunch
//
//  Created by Brian Todi on 2025-02-20.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // setup navigation controller with discover, launch, and coins page
        let discoverVC = ViewController()
        discoverVC.title = "Discover"

        let launchCoinVC = LaunchCoinViewController()
        launchCoinVC.title = "Launch Coin"

        let myCoinsVC = MyCoinsViewController()
        myCoinsVC.title = "My Coins"

        // add each one to navigation controller
        let nav1 = UINavigationController(rootViewController: discoverVC)
        let nav2 = UINavigationController(rootViewController: launchCoinVC)
        let nav3 = UINavigationController(rootViewController: myCoinsVC)

        // dark back ? not working idk why
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundEffect = nil
        navBarAppearance.backgroundColor = UIColor(red: 21/255, green: 24/255, blue: 55/255, alpha: 1.0)
        navBarAppearance.shadowColor = .clear
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        // dark nav bar
        [nav1, nav2, nav3].forEach { nav in
            nav.navigationBar.standardAppearance = navBarAppearance
            nav.navigationBar.scrollEdgeAppearance = navBarAppearance
            nav.navigationBar.compactAppearance = navBarAppearance
            nav.navigationBar.tintColor = .white
            nav.navigationBar.isTranslucent = false
        }

        // tab bar controller for navbar
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [nav1, nav2, nav3]
        tabBarController.tabBar.barTintColor = UIColor(red: 20/255, green: 19/255, blue: 45/255, alpha: 1.0)
        tabBarController.tabBar.tintColor = UIColor.systemGreen
        tabBarController.tabBar.isTranslucent = false

        // set pics and title for each viewcontroller
        nav1.tabBarItem = UITabBarItem(
            title: "Trending",
            image: UIImage(systemName: "flame.fill"),
            selectedImage: UIImage(systemName: "flame.fill")
        )
        nav2.tabBarItem = UITabBarItem(
            title: "Launch Coin",
            image: UIImage(systemName: "plus.circle.fill"),
            selectedImage: UIImage(systemName: "plus.circle.fill")
        )
        nav3.tabBarItem = UITabBarItem(
            title: "My Coins",
            image: UIImage(systemName: "bitcoinsign.circle.fill"),
            selectedImage: UIImage(systemName: "bitcoinsign.circle.fill")
        )

        // setup window
        window = UIWindow(windowScene: windowScene)
        window?.backgroundColor = UIColor(red: 20/255, green: 19/255, blue: 45/255, alpha: 1.0)
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
    }
}
