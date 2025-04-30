import SwiftUI
import PhotosUI
import AVFoundation

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var reviewResult: OutfitReview?
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @State private var navigateToReview: Bool = false
    @State private var cameraPermission: AVAuthorizationStatus = .notDetermined
    @State private var capturedImage: UIImage?
    
    let openAIService = OpenAIService()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera view fills the entire screen
                CameraView(onImageCaptured: { image in
                    handleCapturedImage(image)
                })
                .edgesIgnoringSafeArea(.all)
                
                // Overlay UI elements at the bottom
                VStack {
                    Spacer()
                    
                    HStack(spacing: 60) {
                        // Photo picker button
                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.black.opacity(0.7)))
                        }
                        
                        // Camera capture button
                        Button(action: {
                            // Trigger camera capture (handled by CameraView)
                            NotificationCenter.default.post(name: NSNotification.Name("CapturePhoto"), object: nil)
                        }) {
                            Image(systemName: "camera")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                                .padding(24)
                                .background(Circle().fill(Color.black.opacity(0.7)))
                        }
                        
                        // Placeholder to balance the layout
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 24, height: 24)
                            .padding()
                    }
                    .padding(.bottom, 40)
                }
                
                // Loading overlay
                if isLoading {
                    Color.black.opacity(0.7)
                        .edgesIgnoringSafeArea(.all)
                    
                    ProgressView("Analyzing outfit...")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                }
                
                // Error message overlay
                if let errorMessage = errorMessage {
                    VStack {
                        Spacer()
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.7)))
                            .padding(.bottom, 100)
                    }
                }
                
                // Camera permission denied overlay
                if cameraPermission == .denied {
                    Color.black.opacity(0.9)
                        .edgesIgnoringSafeArea(.all)
                    
                    Text("Camera permission denied. Please change in settings to use.")
                        .foregroundColor(.white)
                        .padding()
                }
                
                // Hidden NavigationLink for review
                NavigationLink(
                    destination: ReviewView(
                        imageData: selectedImageData ?? Data(),
                        review: reviewResult ?? OutfitReview(
                            fit: ReviewParameter(score: 0, comment: "N/A"),
                            color: ReviewParameter(score: 0, comment: "N/A"),
                            step_out_readiness: ReviewParameter(score: 0, comment: "N/A")
                        )
                    ),
                    isActive: $navigateToReview
                ) {
                    EmptyView()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                checkCameraPermission()
            }
            .onChange(of: selectedItem) { newItem in
                handleSelectedItem(newItem)
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func checkCameraPermission() {
        cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
        
        if cameraPermission == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermission = granted ? .authorized : .denied
                }
            }
        }
    }
    
    private func handleSelectedItem(_ newItem: PhotosPickerItem?) {
        Task {
            isLoading = true
            errorMessage = nil
            reviewResult = nil
            selectedImageData = nil
            navigateToReview = false
            
            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                selectedImageData = data
                if let image = UIImage(data: data) {
                    processImage(image)
                } else {
                    errorMessage = "Could not load image."
                    isLoading = false
                }
            } else if newItem != nil {
                errorMessage = "Could not load image data."
                isLoading = false
            } else {
                isLoading = false
            }
        }
    }
    
    private func handleCapturedImage(_ image: UIImage) {
        isLoading = true
        errorMessage = nil
        reviewResult = nil
        
        // Convert UIImage to Data for storage and passing to review
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            selectedImageData = imageData
            processImage(image)
        } else {
            errorMessage = "Could not process captured image."
            isLoading = false
        }
    }
    
    private func processImage(_ image: UIImage) {
        Task {
            do {
                reviewResult = try await openAIService.fetchOutfitReview(image: image)
                navigateToReview = true
            } catch {
                errorMessage = "Error getting review: \(error.localizedDescription)"
                print("API Error: \(error)")
            }
            isLoading = false
        }
    }
}

// Camera view using AVFoundation
struct CameraView: UIViewRepresentable {
    var onImageCaptured: (UIImage) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let captureSession = AVCaptureSession()
        context.coordinator.captureSession = captureSession
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            return view
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        let photoOutput = AVCapturePhotoOutput()
        context.coordinator.photoOutput = photoOutput
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        // Register for photo capture notification
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.capturePhoto),
            name: NSNotification.Name("CapturePhoto"),
            object: nil
        )
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        let parent: CameraView
        var captureSession: AVCaptureSession?
        var photoOutput: AVCapturePhotoOutput?
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        @objc func capturePhoto() {
            guard let photoOutput = photoOutput else { return }
            
            let settings = AVCapturePhotoSettings()
            if let previewPhotoPixelFormatType = settings.availablePreviewPhotoPixelFormatTypes.first {
                settings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
            }
            
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let error = error {
                print("Error capturing photo: \(error)")
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                return
            }
            
            DispatchQueue.main.async {
                self.parent.onImageCaptured(image)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
