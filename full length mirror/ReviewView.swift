import SwiftUI
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.fulllengthmirror", category: "Review")

struct ReviewView: View {
    @Environment(\.presentationMode) var presentationMode

    let imageData: Data
    let review: OutfitReview

    private let imageContainerTargetHeightRatio: CGFloat = 0.42 // Slightly more height for image
    private let parameterSectionWidthRatio: CGFloat = 0.38   // Slightly more width for params

    var body: some View {
        VStack(spacing: 0) {
            // TOP SECTION: Image and Parameters
            HStack(alignment: .top, spacing: 15) { // Increased spacing
                // Image View
                VStack {
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .background(Color.white)
                            .cornerRadius(12) // Slightly larger radius
                            .shadow(color: Color.black.opacity(0.12), radius: 5, x: 0, y: 3)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray.opacity(0.5))
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.height * imageContainerTargetHeightRatio)

                // Parameters List
                VStack(alignment: .leading, spacing: 8) { // Adjusted spacing
                    ForEach(review.orderedParameters, id: \.0) { paramData in
                        ParameterRow(
                            parameterName: paramData.key.capitalized,
                            score: paramData.value.score
                        )
                        if paramData.key != review.orderedParameters.last?.key {
                            Divider().padding(.vertical, 4) // More subtle divider padding
                        }
                    }
                    Spacer() 
                }
                .padding(.leading, 5) // Reduced padding to give params more space
                .frame(width: UIScreen.main.bounds.width * parameterSectionWidthRatio)
                .frame(maxHeight: UIScreen.main.bounds.height * imageContainerTargetHeightRatio)
            }
            .padding(.horizontal, 15)
            .padding(.top, 20) // More padding from top if no nav bar
            .padding(.bottom, 20) // Increased bottom padding for this section

            // COMMENTS SECTION (Simplified)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) { // Spacing for comment items
                    ForEach(review.orderedParameters, id: \.0) { paramData in
                        if !paramData.value.comment.isEmpty {
                            HStack(alignment: .firstTextBaseline) {
                                Text("\(paramData.key.capitalized):")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(UIColor.label))
                                Text(paramData.value.comment)
                                    .font(.subheadline) // Slightly smaller for comment text
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                    .lineSpacing(3)
                                Spacer() // Pushes content to leading
                            }
                        }
                    }
                }
                .padding(.horizontal, 20) // More horizontal padding for comments
                .padding(.top, 10)
                .padding(.bottom, 95) // Ensure enough space above bottom buttons
            }
            // No background or corner radius for the ScrollView itself for a cleaner look
            .padding(.horizontal, 0) // Remove horizontal padding from ScrollView container
            .padding(.bottom, 10)
            
            Spacer()

            // BOTTOM CONTROLS
            HStack(spacing: 15) {
                Button(action: {
                    logger.info("Back button tapped")
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.backward")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                        .padding(16) // Slightly larger tap area
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                }

                Button(action: {
                    logger.info("Screenshot & Add to Story button tapped")
                }) {
                    Text("Screenshot & Add to Story")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white) // White text color
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "EF008C")) // New background color
                        .cornerRadius(16)
                        .shadow(color: Color(hex: "EF008C").opacity(0.4), radius: 6, x: 0, y: 3) // Adjusted shadow
                }
            }
            .padding(.horizontal, 20) // Increased padding for bottom controls
            .padding(.bottom, 15) // More space from bottom edge
            .padding(.top, 5)
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true) // Hide the entire top navigation bar
        .onAppear {
            logger.info("Review page opened with new design iteration")
        }
    }

    static func scoreColor(_ score: Double) -> Color {
        switch score {
        case 4.0...5.0: return .green // Adjusted ranges slightly for green
        case 3.0..<4.0: return Color(UIColor.systemTeal)
        case 2.0..<3.0: return .orange
        default: return .red
        }
    }
}

struct ParameterRow: View {
    let parameterName: String
    let score: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(parameterName)
                .font(.callout) // Slightly smaller for less emphasis than score
                .fontWeight(.medium)
                .foregroundColor(Color(UIColor.secondaryLabel))
                .lineLimit(1)

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(String(format: "%.1f", score))
                    .font(.system(size: 30, weight: .bold, design: .rounded)) // Larger score
                    .foregroundColor(ReviewView.scoreColor(score))
                Text("/5")
                    .font(.system(size: 14, weight: .semibold, design: .rounded)) // Adjusted size & design
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                    .padding(.bottom, 5) // Fine-tune baseline alignment
            }
        }
    }
}

// CommentRow helper view is removed as comments are now directly in ReviewView's ScrollView

struct ReviewView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleImageData = UIImage(systemName: "figure.dress.line.vertical.figure")?.pngData() ?? UIImage(systemName: "photo")!.pngData()!

        let jsonString = """
        {
            "parameters": {
                "Fit": { 
                    "score": 4.0,
                    "comment": "Jeans are a bit too baggy for the current trend, but the top fits well."
                },
                "Color": {
                    "score": 3.0,
                    "comment": "Green check contrasts okay, but the brown bag and dark pants lack some harmony. Consider a different bag color."
                },
                "Readiness": { 
                    "score": 4.0,
                    "comment": "Outfit suits a casual day out; looks practical and socially acceptable for many informal settings."
                },
                "Style": {
                    "score": 2.2,
                    "comment": "While components are fine, the overall style feels a bit disjointed. The top is preppy, pants are more street."
                },
                "Accessorizing": {
                    "score": 3.5,
                    "comment": "The necklace is a nice touch. Shoes are okay but could be more impactful."
                }
            }
        }
        """

        let decoder = JSONDecoder()
        if let jsonData = jsonString.data(using: .utf8),
           let sampleReview = try? decoder.decode(OutfitReview.self, from: jsonData) {
            ReviewView(imageData: sampleImageData, review: sampleReview)
//                .preferredColorScheme(.dark) 
        } else {
            Text("Error loading preview data. Check OutfitReview model and JSON.")
                .padding()
        }
    }
}

// Make sure OutfitReview and ReviewParameter are defined correctly elsewhere
// For example:
// struct OutfitReview: Decodable {
//     let parameters: [String: ReviewParameter]
//     var orderedParameters: [(key: String, value: ReviewParameter)] {
//         // Define your desired order, e.g., alphabetically or a predefined list
//         parameters.sorted { $0.key < $1.key }
//     }
// }
//
// struct ReviewParameter: Decodable {
//     let score: Double
//     let comment: String
// }
// The logger was here, but it's defined globally at the top of the file.
// The ReviewSection view is no longer needed with the new design.
// Removed old ReviewSection and its scoreColor function as it's now in ReviewView or ParameterRow
