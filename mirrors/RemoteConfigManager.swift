import Foundation
import Firebase
import FirebaseCore
import FirebaseRemoteConfig

class RemoteConfigManager {
    static let shared = RemoteConfigManager()
    private let remoteConfig: RemoteConfig
    private var hasInitialFetch = false
    
    // Remote Config keys
    enum ConfigKeys {
        static let outfitPrompt = "outfit_prompt_text"
        static let initialSnapsCount = "initial_snaps_count"
        static let openAIAPIKey = "oaikey"
    }
    
    // Default values
    private let defaultPrompt: String
    private let defaultSnapsCount = 14  // Match Firebase default
    
    private init() {
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        // Set minimum fetch interval to 0 for testing
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        
        // Load default prompt from file for initial setup
        if let promptURL = Bundle.main.url(forResource: "OutfitPrompt", withExtension: "txt"),
           let promptText = try? String(contentsOf: promptURL, encoding: .utf8) {
            defaultPrompt = promptText
        } else {
            defaultPrompt = "Review the outfit in the photo. Return a JSON object with fit, color, and step_out_readiness scores and comments."
        }
        
        // Set default values
        let defaults: [String: NSObject] = [
            ConfigKeys.initialSnapsCount: NSNumber(value: defaultSnapsCount),
            ConfigKeys.outfitPrompt: defaultPrompt as NSString,
            ConfigKeys.openAIAPIKey: "" as NSString
        ]
        remoteConfig.setDefaults(defaults)
        
        // Initial fetch
        Task {
            await fetchAndActivate()
            hasInitialFetch = true
        }
    }
    
    @discardableResult
    func fetchAndActivate() async -> RemoteConfigFetchAndActivateStatus {
        do {
            let status = try await remoteConfig.fetchAndActivate()
            return status
        } catch {
            print("Error fetching remote config: \(error.localizedDescription)")
            return .error
        }
    }
    
    var initialSnapsCount: Int {
        // Force a fetch if we haven't done the initial fetch yet
        if !hasInitialFetch {
            Task {
                await fetchAndActivate()
                hasInitialFetch = true
            }
        }
        return remoteConfig[ConfigKeys.initialSnapsCount].numberValue.intValue
    }
    
    var openAIAPIKey: String {
        remoteConfig[ConfigKeys.openAIAPIKey].stringValue ?? ""
    }
    
    var outfitPrompt: String {
        remoteConfig[ConfigKeys.outfitPrompt].stringValue ?? defaultPrompt
    }
    
    func setupRealTimeUpdates() {
        remoteConfig.addOnConfigUpdateListener { [weak self] configUpdate, error in
            guard error == nil else {
                print("Error setting up real-time updates: \(error!.localizedDescription)")
                return
            }
            
            Task {
                await self?.fetchAndActivate()
            }
        }
    }
} 