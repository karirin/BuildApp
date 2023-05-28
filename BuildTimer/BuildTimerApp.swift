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
//import Stripe

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
//    StripeAPI.defaultPublishableKey = "rk_test_51N3DcqBO3QEchW1Q27GZPygqldSRkBPqcAkT0kOd41l6CRHYlHNuPwIvrmSgMexgtsQPmZhGuwChPyVpm1TPNssa00zFxIFuXj"
    return true
  }
}

func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
}

@main
struct BuildTimer: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
//    init() {
//        // Stripeの初期化
//        StripeAPI.defaultPublishableKey = "pk_test_51N3DcqBO3QEchW1QIw7BtlYtoiYGYu4DbPaSeup4D772CTMhah2LCo5A3zFXXtI79Spuk0DSWSFTBWPvQRlbEvjk00Mb0OsBZK"
//    }
    var body: some Scene {
        WindowGroup {
//            if Auth.auth().currentUser != nil {
                TopView()// メイン画面
//            } else {・
//                GoogleAuthView() // ログイン画面
//            }
        }
    }
}
