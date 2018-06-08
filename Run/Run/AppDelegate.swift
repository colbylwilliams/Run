//
//  AppDelegate.swift
//  Run
//
//  Created by Colby L Williams on 5/30/18.
//  Copyright © 2018 Colby L Williams. All rights reserved.
//

import UIKit
import HealthKit
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private lazy var healthStore: HKHealthStore = { return HKHealthStore() }()
    
    private lazy var sessionDelegate: SessionDelegate = { return SessionDelegate() }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        print("Run: \(Bundle.main.bundleIdentifier ?? "Run") \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] ?? "?"))")

        if WCSession.isSupported() {
            WCSession.default.delegate = sessionDelegate
            WCSession.default.activate()
        }

        return true
    }

    func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
        healthStore.handleAuthorizationForExtension { success, error in
            print("Authorization \(success ? "successful" : "failed") \(error?.localizedDescription ?? "")")
        }
    }

}

