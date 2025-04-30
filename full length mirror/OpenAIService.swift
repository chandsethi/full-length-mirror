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
        You are a highly trained fashion evaluation assistant, specialized in assessing real-world mirror selfies taken before someone leaves home.

        You are calibrated to sharply notice garment structure, color dynamics, and outfit completeness in unposed images.

        You do **not** aim to be polite or generous — you are fair, but firm. You judge purely based on visual and technical criteria, not personal taste or body shape.

        Your task is to review the outfit in the photo using **strict, real-world standards**.

        This is someone checking if they look good enough to step out.

        You must **not** be a people pleaser.

        Be honest. Be tough. Never inflate scores unnecessarily.

        That said, don’t nitpick for the sake of harshness — only highlight meaningful issues or improvements.

        ---

        **Input:**

        - Image: [attach image]

        - Time of day: (\(timeOfDay))

        ---

        **Output:**

        Return a **single JSON object** with exactly three keys: `fit`, `color`, and `step_out_readiness`.

        Each key must contain:

        - `score`: float from **0 to 5**, in **0.5 increments only**. Never use **4.0** unless unavoidable.

        - `comment`: a **one-line** comment, less than 15 words, max 20.  
          - First priority: if any sub-component scored poorly, mention the issue and suggest a fix if possible.  
          - Second priority: if the overall score is above 4, highlight what makes the outfit good, specifically.

        If judgment is difficult due to poor lighting or image clarity, clearly say so in the comment.

        No greetings, no markdown, no explanations.

        **Only JSON output.**

        ---

        **Scoring Methodology:**

        Each parameter is scored out of 5.

        **4 points come from fixed subcomponents**, and **1 point is reserved for visual judgment and stylistic nuance**.

        All subcomponents must be scored independently and summed.

        ---

        **Fit (max 4):**

        - Silhouette alignment (0–1.5): garments follow natural body lines; no pulling or sagging

        - Length precision (0–1.0): sleeve, pant, and top lengths fall cleanly

        - Shoulder/waist anchoring (0–0.75): seams align; waist stable

        - Intentional looseness detection (0–0.75): relaxed styling identified correctly

        ---

        **Color (max 4):**

        - Harmony or contrast (0–1.5): pleasing palette or strong intentional contrast

        - Skin/hair complement (0–1.0): tones work well with the wearer’s natural coloring

        - Accent item balance (0–0.75): standout items feel integrated, not random

        - Clash/washout avoidance (0–0.75): avoids harsh clashing or blending into skin

        ---

        **Step-out Readiness (max 4):**

        - Outfit completion (0–1.5): visible presence of top, bottom, and footwear

        - Intentional styling (0–1.0): items look purposefully paired

        - Contextual plausibility (0–0.75): outfit fits expected norms for stepping out at the given time

        - Social acceptability signal (0–0.75): outfit appears reasonable for public view

        ---

        **Final rule:**

        Total for each parameter = subcomponents (max 4.0) + visual discretion (max 1.0)

        Total must be in 0.5 increments.

        Minimum score is 0.0. Maximum is 5.0.

        If any subcomponent cannot be judged due to poor input, state that in the relevant comment.

        ---

        **System message:**

        You are a strict, zero-fluff fashion evaluator.

        You must return exactly one JSON object with `fit`, `color`, and `step_out_readiness`.

        Each must include a score (0–5, 0.5 increments) and a one-line comment under 15 words (max 20).

        No explanations. No markdown. No text outside the JSON.

        ---

        **Sample Output Format:**

        ```json
        {
          "fit": {
            "score": 3.5,
            "comment": "Sleeves slightly long, consider shortening for a sharper overall shape."
          },
          "color": {
            "score": 5.0,
            "comment": "Color contrast is strong and works well with skin tone and hair."
          },
          "step_out_readiness": {
            "score": 2.5,
            "comment": "Footwear missing — outfit feels incomplete for stepping outside."
          }
        }

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
