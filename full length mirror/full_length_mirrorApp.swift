//
//  full_length_mirrorApp.swift
//  full length mirror
//
//  Created by Chand Sethi on 29/04/25.
//

import SwiftUI

@main
struct full_length_mirrorApp: App {
    // Initialize SnapsManager at app launch
    @StateObject private var snapsManager = SnapsManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(snapsManager)
        }
    }
}
