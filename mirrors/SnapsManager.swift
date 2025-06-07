import Foundation
import SwiftUI

// Model for tracking snap credit transactions
struct SnapTransaction: Codable {
    let id: UUID
    let amount: Int
    let timestamp: Date
    let type: String
    
    init(amount: Int, type: String) {
        self.id = UUID()
        self.amount = amount
        self.timestamp = Date()
        self.type = type
    }
}

// Main class to manage snap credits
class SnapsManager: ObservableObject {
    private enum Constants {
        static let snapsCountKey = "snapsCount"
        static let transactionLogFileName = "snap_transactions.json"
        static let keychainService = "com.mirrors.snaps"
        static let keychainAccount = "user"
        static let firstLaunchFlagValue = "true"
    }
    
    @Published private(set) var remainingSnaps: Int
    
    static let shared = SnapsManager()
    
    private init() {
        let hasLaunchedBeforeData = KeychainHelper.get(service: Constants.keychainService, account: Constants.keychainAccount)
        let hasLaunchedBefore = hasLaunchedBeforeData != nil

        if hasLaunchedBefore {
            // Not a true first launch. Could be a reinstall.
            // Load from UserDefaults. If it's a reinstall, this will default to 0.
            self.remainingSnaps = UserDefaults.standard.integer(forKey: Constants.snapsCountKey)
        } else {
            // True first launch
            self.remainingSnaps = RemoteConfigManager.shared.initialSnapsCount
            
            // Save initial snaps to UserDefaults
            UserDefaults.standard.set(self.remainingSnaps, forKey: Constants.snapsCountKey)
            logTransaction(SnapTransaction(amount: self.remainingSnaps, type: "init"))
            
            // Set the flag in Keychain to prevent re-crediting on reinstall
            if let firstLaunchData = Constants.firstLaunchFlagValue.data(using: .utf8) {
                KeychainHelper.set(data: firstLaunchData, service: Constants.keychainService, account: Constants.keychainAccount)
            }
        }
    }
    
    // Check if user has enough snaps
    func hasAvailableSnaps() -> Bool {
        return remainingSnaps > 0
    }
    
    // Use a snap (returns success status)
    func useSnap() -> Bool {
        guard hasAvailableSnaps() else {
            return false
        }
        
        remainingSnaps -= 1
        saveSnapsCount()
        
        // Log consumption transaction
        logTransaction(SnapTransaction(amount: -1, type: "consumption"))
        
        return true
    }
    
    // Save the current snap count
    private func saveSnapsCount() {
        UserDefaults.standard.set(remainingSnaps, forKey: Constants.snapsCountKey)
    }
    
    // Log a transaction to the local file
    private func logTransaction(_ transaction: SnapTransaction) {
        // Get the documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Unable to access documents directory")
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(Constants.transactionLogFileName)
        
        // Load existing transactions if available
        var transactions: [SnapTransaction] = []
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                transactions = try JSONDecoder().decode([SnapTransaction].self, from: data)
            } catch {
                print("Error loading transaction log: \(error.localizedDescription)")
            }
        }
        
        // Add new transaction
        transactions.append(transaction)
        
        // Save updated transactions
        do {
            let data = try JSONEncoder().encode(transactions)
            try data.write(to: fileURL)
        } catch {
            print("Error saving transaction log: \(error.localizedDescription)")
        }
    }
} 