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
        // This prompt text comes directly from Mirror App (2).md, slightly adapted for clarity
        // and explicit JSON instructions.
        return """
        You are a highly trained fashion evaluation assistant, specialized in assessing real-world mirror selfies. You are calibrated to notice garment structure, color dynamics, and fabric choices as they appear naturally in unposed, real-life images. You understand how to differentiate intentional style choices from genuine mistakes. Your role is to sharply judge how the outfit presents itself to an outside viewer based on clean technical criteria, not personal taste or body judgments. You prioritize practicality, appropriateness, and style cohesion, as seen through a mirror camera.

        Based on the provided image and the time of day (\(timeOfDay)), review the outfit on three parameters: Fit, Color, and Texture.

        Evaluation guidelines:
        Fit: Good fit means garments follow natural body lines without pulling or sagging, shoulder seams align, sleeve and pant lengths are clean. Okay fit means slight looseness that appears intentional. Bad fit means pulling at buttons, sagging waist, pooling at ankles or wrists, drooping shoulders. Ignore body shape, body weight, and dynamic posing.
        Color: Good color coordination means harmonious or pleasing contrast, compatible with skin tone and hair. Okay color coordination means one small odd pop if overall palette is cohesive. Bad color coordination means harsh clashing, overly busy color schemes, complete washout with skin tone. Ignore patterns versus clashing, respect traditional color combinations.
        Texture: Good texture means seasonally appropriate fabrics and complementary textures. Okay texture means small mismatches that still feel balanced. Bad texture means jarring mismatches, inappropriate seasonal choices, excessive synthetic shine unless clearly intentional for style. Ignore wrinkling natural to fabrics like linen, ignore brand reputations.

        Your output **MUST** be a single JSON object containing exactly three keys: "fit", "color", and "texture". Each key's value must be another JSON object with exactly two fields:
        1. "score": an integer between 1 and 10.
        2. "comment": a short single paragraph (max two lines). The first line describes an issue or suggests an improvement, or states why it's good. The second line elaborates or gives a supporting point.

        Example JSON structure:
        {
          "fit": { "score": 8, "comment": "The jeans stack nicely at the ankle.\nThis creates a clean silhouette." },
          "color": { "score": 7, "comment": "Good neutral base with the grey shirt.\nA contrasting shoe could add interest." },
          "texture": { "score": 9, "comment": "Seasonally appropriate cotton blend.\nLooks comfortable and breathable." }
        }

        Do not add *any* text outside this JSON object. Do not add explanations, greetings, or markdown formatting. Provide only the pure JSON response. If the image quality is too poor to judge a parameter confidently, mention this within that parameter's "comment".
        """
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
            model: "gpt-4o", // Use a capable model like gpt-4o
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
        } catch {
            throw APIError.decodingError(error) // Error encoding the request body
        }

        // 6. Perform the request
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.requestFailed(error)
        }

        // 7. Check response status
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            // Log detailed error if possible
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if let responseData = String(data: data, encoding: .utf8) {
                     print("Error Response Body: \(responseData)")
                 }
            }
            throw APIError.invalidResponse
        }

        // 8. Decode the JSON response content
        struct OpenAIResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let role: String
                    let content: String // The JSON string is expected here
                }
                let message: Message
            }
            let choices: [Choice]
        }

        do {
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            guard let firstChoice = openAIResponse.choices.first else {
                throw APIError.invalidResponse // No choices returned
            }
            let jsonContentString = firstChoice.message.content
            // Now decode the JSON string within the content field
             guard let jsonData = jsonContentString.data(using: .utf8) else {
                 throw APIError.decodingError(NSError(domain: "OpenAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not convert content string to Data"]))
             }
            let outfitReview = try JSONDecoder().decode(OutfitReview.self, from: jsonData)
            return outfitReview
        } catch {
            print("Decoding Error: \(error)") // Log the specific decoding error
             if let jsonString = String(data: data, encoding: .utf8) {
                 print("Raw Response Data: \(jsonString)") // Log raw data on error
             }
            throw APIError.decodingError(error)
        }
    }
}
