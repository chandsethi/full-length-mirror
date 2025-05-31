import Foundation

enum Config {
    static var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Configuration", ofType: "plist"),
              let configDict = NSDictionary(contentsOfFile: path),
              let key = configDict["OpenAIAPIKey"] as? String else {
            fatalError("Configuration.plist not found or OpenAIAPIKey key is missing/invalid.")
        }
        return key
    }
}
