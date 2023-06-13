//
//  BuildAppApp.swift
//  BuildApp
//
//  Created by hashimo ryoya on 2023/04/15.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import GoogleMobileAds
//import Stripe

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
      FirebaseApp.configure()

      GADMobileAds.sharedInstance().start(completionHandler: nil)
      return true
  }
}

func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
}

@main
struct BuildTimer: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
                TopView()
        }
    }
}
