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
                ReviewSection(title: "Texture", parameter: review.texture)

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
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            HStack {
                Text("Score:")
                Text("\(parameter.score)/10")
                    .fontWeight(.bold)
            }
            Text("Comment:")
            Text(parameter.comment)
                .font(.body) // Standard body font
                .padding(.leading, 5) // Indent comment slightly
        }
        .padding(.vertical, 5) // Add some vertical spacing
        Divider() // Separator between sections
    }
}


// Add a Preview Provider for easier design iteration
struct ReviewView_Previews: PreviewProvider {
    static var previews: some View {
        // Create sample data for the preview
        let sampleImageData = UIImage(systemName: "tshirt.fill")?.pngData() ?? Data()
        let sampleReview = OutfitReview(
            fit: ReviewParameter(score: 8, comment: "Fits well across the shoulders.\nSleeves are a good length."),
            color: ReviewParameter(score: 6, comment: "Neutral color, versatile.\nCould use a pop of color in accessories."),
            texture: ReviewParameter(score: 7, comment: "Standard cotton weave.\nLooks comfortable for daily wear.")
        )

        // Embed in NavigationView for preview context
        NavigationView {
            ReviewView(imageData: sampleImageData, review: sampleReview)
        }
    }
}
