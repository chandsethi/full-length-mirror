import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var reviewResult: OutfitReview?
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @State private var navigateToReview: Bool = false // Navigation trigger

    let openAIService = OpenAIService()

    var body: some View {
        // Use NavigationView to enable NavigationLink and back button
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Analyzing outfit...")
                        .padding()
                } else {
                    // Display the selected image preview if available
                     if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                         Image(uiImage: uiImage)
                             .resizable()
                             .scaledToFit()
                             .frame(maxHeight: 300) // Limit preview size
                             .cornerRadius(8)
                             .padding(.horizontal)
                     } else {
                         // Placeholder or instruction text
                         Text("Select a photo of your outfit to get started.")
                             .font(.headline)
                             .foregroundColor(.gray)
                             .padding()
                     }


                    // Photo Picker Button
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images, // Only allow images
                        photoLibrary: .shared() // Use the shared photo library
                    ) {
                        Text("Select Outfit Photo")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    // Handle changes in the selected photo item
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            isLoading = true // Start loading indicator
                            errorMessage = nil // Clear previous errors
                            reviewResult = nil // Clear previous results
                            selectedImageData = nil // Clear previous image data
                            navigateToReview = false // Reset navigation trigger

                            // Load image data from the selected item
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                                if let image = UIImage(data: data) {
                                    // Call the API service
                                    do {
                                        reviewResult = try await openAIService.fetchOutfitReview(image: image)
                                        navigateToReview = true // Set flag to trigger navigation *after* API success
                                    } catch {
                                        errorMessage = "Error getting review: \(error.localizedDescription)"
                                        print("API Error: \(error)") // Log detailed error
                                    }
                                } else {
                                    errorMessage = "Could not load image."
                                }
                            } else if newItem != nil {
                                // Handle case where loading data fails but an item was selected
                                errorMessage = "Could not load image data."
                            }
                            // Reset selection if needed or keep it to show preview
                            // selectedItem = nil // Uncomment if you want picker to reset fully

                            isLoading = false // Stop loading indicator
                        }
                    }

                    // Display error messages if any
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }

                // Hidden NavigationLink triggered by state
                // This navigates *only* when navigateToReview is true and we have results
                NavigationLink(
                    destination: ReviewView(
                        imageData: selectedImageData ?? Data(), // Pass image data
                        review: reviewResult ?? OutfitReview( // Pass review data or default
                            fit: ReviewParameter(score: 0, comment: "N/A"),
                            color: ReviewParameter(score: 0, comment: "N/A"),
                            texture: ReviewParameter(score: 0, comment: "N/A")
                        )
                    ),
                    isActive: $navigateToReview // Bind navigation to the state flag
                ) {
                    EmptyView() // Link is invisible, triggered programmatically
                }
            }
            .navigationTitle("Outfit Picker") // Set a title for the view
        }
        .navigationViewStyle(.stack) // Use stack style for standard navigation
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
