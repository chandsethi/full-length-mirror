import SwiftUI // For UIImage
import Foundation

class OpenAIService {

    private let apiKey = Config.apiKey // Use the secure method from step 1
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    enum APIError: Error {
        case invalidURL
        case requestFailed(Error)
        case invalidResponse
        case decodingError(Error)
        case dataConversionError
    }

    // Refined prompt incorporating JSON enforcement and schema
    private func createPrompt(imageBase64: String, timeOfDay: String) -> String {
        // Read the base prompt from file
        guard let promptURL = Bundle.main.url(forResource: "OutfitPrompt", withExtension: "txt"),
              let basePrompt = try? String(contentsOf: promptURL, encoding: .utf8) else {
            // If file reading fails, return a minimal prompt to avoid crashing
            return "Review the outfit in the photo. Return a JSON object with fit, color, and step_out_readiness scores and comments."
        }
        
        // Add the dynamic input section
        let inputSection = """
        
        **Input:**
        
        - Image: [attach image]
        - Time of day: (\(timeOfDay))
        
        """
        
        // Insert the input section after the first "---" marker
        if let range = basePrompt.range(of: "---") {
            let firstPart = basePrompt[..<range.lowerBound]
            let secondPart = basePrompt[range.upperBound...]
            return String(firstPart) + "---\n" + inputSection + String(secondPart)
        }
        
        // Fallback: just append input section if we can't find the marker
        return basePrompt + "\n" + inputSection
    }


    func fetchOutfitReview(image: UIImage) async throws -> OutfitReview {
        // 1. Convert UIImage to Base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { // Use JPEG for smaller size
            throw APIError.dataConversionError
        }
        let base64ImageString = imageData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64ImageString)"

        // 2. Get current time as ISO string
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Common format
        let timeOfDayString = isoFormatter.string(from: Date())

        // 3. Construct the prompt text
        let promptText = createPrompt(imageBase64: base64ImageString, timeOfDay: timeOfDayString)

        // 4. Create the request payload
        let payload = OpenAIRequestPayload(
            model: "gpt-4.1-mini",  // Using the model from the latest OpenAI documentation
            messages: [
                .init(role: "system", content: .string("You are a strict, no-nonsense outfit reviewer designed for a mirror selfie review app. You must output only valid JSON matching the requested structure.")),
                 .init(role: "user", content: .array([
                    .init(text: promptText), // Main instructions
                    .init(imageUrl: dataURI, detail: "high") // Send image data URI and request high detail
                 ]))
            ],
            max_tokens: 300, // Adjust as needed
            response_format: .init(type: "json_object") // Crucial for enforcing JSON output
        )


        // 5. Create URLRequest
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(payload)
            // Log the request payload for debugging
            if let requestBody = String(data: request.httpBody!, encoding: .utf8) {
                print("Request Payload: \(requestBody)")
            }
        } catch {
            print("Request Encoding Error: \(error)")
            print("Error Details: \(error.localizedDescription)")
            throw APIError.decodingError(error)
        }

        // 6. Perform the request
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("Network Error: \(error)")
            print("Error Details: \(error.localizedDescription)")
            throw APIError.requestFailed(error)
        }

        // 7. Check response status
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid Response Type: Response is not HTTPURLResponse")
            throw APIError.invalidResponse
        }

        // Log response headers for debugging
        print("Response Headers: \(httpResponse.allHeaderFields)")
        print("Status Code: \(httpResponse.statusCode)")

        // Always try to print response body for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response Body: \(responseString)")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            print("HTTP Error: \(httpResponse.statusCode)")
            if let responseData = String(data: data, encoding: .utf8) {
                print("Error Response: \(responseData)")
            }
            throw APIError.invalidResponse
        }

        // 8. Decode the JSON response content
        struct OpenAIResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let role: String
                    let content: String
                }
                let message: Message
                let finish_reason: String? // Add this to see why the response might have ended
            }
            let choices: [Choice]
            let model: String? // Add this to confirm which model was actually used
            let usage: Usage? // Add this to see token usage
        }

        struct Usage: Decodable {
            let prompt_tokens: Int
            let completion_tokens: Int
            let total_tokens: Int
        }

        do {
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            
            // Log model and usage information
            if let model = openAIResponse.model {
                print("Model Used: \(model)")
            }
            if let usage = openAIResponse.usage {
                print("Token Usage - Prompt: \(usage.prompt_tokens), Completion: \(usage.completion_tokens), Total: \(usage.total_tokens)")
            }
            
            guard let firstChoice = openAIResponse.choices.first else {
                print("No choices in response")
                throw APIError.invalidResponse
            }
            
            // Log finish reason if available
            if let finishReason = firstChoice.finish_reason {
                print("Finish Reason: \(finishReason)")
            }
            
            let jsonContentString = firstChoice.message.content
            print("Response Content: \(jsonContentString)")
            
            guard let jsonData = jsonContentString.data(using: .utf8) else {
                print("Failed to convert content string to Data")
                throw APIError.decodingError(NSError(domain: "OpenAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not convert content string to Data"]))
            }
            
            do {
                let outfitReview = try JSONDecoder().decode(OutfitReview.self, from: jsonData)
                return outfitReview
            } catch {
                print("Review JSON Parsing Error: \(error)")
                print("Invalid JSON Content: \(jsonContentString)")
                throw APIError.decodingError(error)
            }
        } catch {
            print("Response Decoding Error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw Response: \(jsonString)")
            }
            throw APIError.decodingError(error)
        }
    }
}
