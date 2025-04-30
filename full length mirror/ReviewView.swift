import SwiftUI

struct ReviewView: View {
    let imageData: Data // Receive image data
    let review: OutfitReview // Receive the structured review

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Display the selected image
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .padding(.horizontal)
                } else {
                    Text("Could not display image.")
                        .foregroundColor(.red)
                }

                // Display Review Details
                ReviewSection(title: "Fit", parameter: review.fit)
                ReviewSection(title: "Color", parameter: review.color)
                ReviewSection(title: "Ready to Step Out?", parameter: review.step_out_readiness)

                Spacer() // Push content to the top
            }
            .padding() // Add padding around the VStack content
        }
        .navigationTitle("Outfit Review") // Title for this view
        .navigationBarTitleDisplayMode(.inline) // Keep title small
        // The back button is automatically provided by NavigationView
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
                // Score circle
                ZStack {
                    Circle()
                        .fill(scoreColor(parameter.score))
                        .frame(width: 45, height: 45)
                    Text(String(format: "%.1f", parameter.score))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // Comment
                Text(parameter.comment)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 10)
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


// Add a Preview Provider for easier design iteration
struct ReviewView_Previews: PreviewProvider {
    static var previews: some View {
        // Create sample data for the preview
        let sampleImageData = UIImage(systemName: "tshirt.fill")?.pngData() ?? Data()
        let sampleReview = OutfitReview(
            fit: ReviewParameter(score: 3.5, comment: "Sleeves slightly long, consider shortening for a sharper overall shape."),
            color: ReviewParameter(score: 5.0, comment: "Color contrast is strong and works well with skin tone and hair."),
            step_out_readiness: ReviewParameter(score: 2.5, comment: "Footwear missing — outfit feels incomplete for stepping outside.")
        )

        // Embed in NavigationView for preview context
        NavigationView {
            ReviewView(imageData: sampleImageData, review: sampleReview)
        }
    }
}
