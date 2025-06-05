import SwiftUI
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.fulllengthmirror", category: "Review")

struct ReviewView: View {
    let imageData: Data // Receive image data
    let review: OutfitReview // Receive the structured review

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Display the selected image
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .cornerRadius(8)
                        .padding(.horizontal)
                } else {
                    Text("Could not display image.")
                        .foregroundColor(.red)
                }

                // Display Review Details - now using orderedParameters
                ForEach(review.orderedParameters, id: \.key) { parameter in
                    ReviewSection(title: parameter.key.capitalized, parameter: parameter.value)
                }

                Spacer() // Push content to the top
            }
            .padding() // Add padding around the VStack content
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        // Back gesture still works with the navigation bar hidden
        .onAppear {
            logger.info("Review page opened")
        }
    }
}

// Helper view for displaying each review parameter
struct ReviewSection: View {
    let title: String
    let parameter: ReviewParameter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                // Score rectangle with formatted score
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(scoreColor(parameter.score))
                        .frame(width: 65, height: 35)
                    HStack(alignment: .bottom, spacing: 1) {
                        Text(String(format: "%.1f", parameter.score))
                            .font(.system(size: 20, weight: .bold))
                        Text("/5")
                            .font(.system(size: 12, weight: .medium))
                            .offset(y: -2)
                    }
                    .foregroundColor(.white)
                }
                
                // Comment
                Text(parameter.comment)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
        Divider()
    }
    
    // Color based on score
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 4.5...5.0: return .green
        case 3.5..<4.5: return .blue
        case 2.5..<3.5: return .orange
        default: return .red
        }
    }
}

// Preview provider needs to be updated for the new model
struct ReviewView_Previews: PreviewProvider {
    static var previews: some View {
        // Create sample data for the preview
        let sampleImageData = UIImage(systemName: "tshirt.fill")?.pngData() ?? Data()
        
        // Create a JSON decoder
        let decoder = JSONDecoder()
        
        // Sample JSON string
        let jsonString = """
        {
            "parameters": {
                "fit": {
                    "score": 3.5,
                    "comment": "Sleeves slightly long, consider shortening for a sharper overall shape."
                },
                "color": {
                    "score": 5.0,
                    "comment": "Color contrast is strong and works well with skin tone and hair."
                }
            }
        }
        """
        
        // Create preview view
        if let jsonData = jsonString.data(using: .utf8),
           let sampleReview = try? decoder.decode(OutfitReview.self, from: jsonData) {
            NavigationView {
                ReviewView(imageData: sampleImageData, review: sampleReview)
            }
        }
    }
}
