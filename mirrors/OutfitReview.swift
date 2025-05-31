import Foundation

// Structure to hold the review for a single parameter
struct ReviewParameter: Codable, Identifiable {
    let id = UUID() // For SwiftUI lists if needed later
    var score: Double  // Changed from Int to Double to handle decimal scores
    var comment: String
}

// Main structure for the entire outfit review JSON object
struct OutfitReview: Codable {
    private var parameters: [String: ReviewParameter]
    private var parameterOrder: [String]  // To maintain order of parameters
    
    // Custom coding keys for maintaining order
    private enum CodingKeys: String, CodingKey {
        case parameters
    }
    
    // Custom initializer from decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        parameters = try container.decode([String: ReviewParameter].self, forKey: .parameters)
        // Store keys in order they appear in JSON
        parameterOrder = Array(parameters.keys)
    }
    
    // Custom encoder to maintain structure
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(parameters, forKey: .parameters)
    }
    
    // Access parameters in order
    var orderedParameters: [(key: String, value: ReviewParameter)] {
        parameterOrder.compactMap { key in
            guard let param = parameters[key] else { return nil }
            return (key, param)
        }
    }
    
    // Subscript access
    subscript(key: String) -> ReviewParameter? {
        get {
            return parameters[key]
        }
    }
}

// Example structure for the API request payload
struct OpenAIRequestPayload: Codable {
    struct Message: Codable {
        let role: String
        let content: Content

        enum Content: Codable {
            case string(String)
            case array([ContentPart])

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let string = try? container.decode(String.self) {
                    self = .string(string)
                    return
                }
                if let array = try? container.decode([ContentPart].self) {
                    self = .array(array)
                    return
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Content could not be decoded as String or Array<ContentPart>")
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .string(let string):
                    try container.encode(string)
                case .array(let array):
                    try container.encode(array)
                }
            }
        }


        struct ContentPart: Codable {
            let type: String // "text" or "image_url"
            let text: String?
            struct ImageURL: Codable {
                let url: String // "data:image/jpeg;base64,{base64_image}"
                 let detail: String? // Optional: "low", "high", "auto" (default)
            }
            let image_url: ImageURL?

             // Initializer for text content part
            init(type: String = "text", text: String) {
                self.type = type
                self.text = text
                self.image_url = nil
            }

            // Initializer for image content part
            init(type: String = "image_url", imageUrl: String, detail: String? = "auto") {
                self.type = type
                self.text = nil
                self.image_url = ImageURL(url: imageUrl, detail: detail)
            }
        }
    }

    struct ResponseFormat: Codable {
         let type: String // e.g., "json_object"
     }

    let model: String
    let messages: [Message]
    let max_tokens: Int
    let response_format: ResponseFormat? // Make optional if not always used
}
