//
//  full_length_mirrorApp.swift
//  full length mirror
//
//  Created by Chand Sethi on 29/04/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Test Firebase configuration
        print("Firebase configuration complete")
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            print("Running with bundle identifier: \(bundleIdentifier)")
        }
        
        return true
    }
}

@main
struct full_length_mirrorApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Initialize SnapsManager at app launch
    @StateObject private var snapsManager = SnapsManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(snapsManager)
        }
    }
}
