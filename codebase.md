# Full Length Mirror App Codebase Summary

## version: 30 april 3pm

### 1. Product Summary

**Full Length Mirror** is an iOS application that helps users evaluate their outfits before stepping out. 

**Key Features:**
- Real-time camera capture for outfit photos
- Photo library integration for existing images
- AI-powered outfit analysis using OpenAI's GPT-4.1-mini
- Detailed scoring system for fit, color, and step-out readiness
- Beautiful UI with instant feedback

**User Journey:**
1. User opens app and sees camera view
2. Can either:
   - Take a photo using the camera
   - Select an existing photo from library
3. App sends image to OpenAI for analysis
4. Receives detailed outfit review with scores and comments
5. Views breakdown of fit, color, and step-out readiness scores

### 2. Project Summary

**Core Files:**
- `full_length_mirrorApp.swift`: Main app entry point
- `ContentView.swift`: Main UI and camera functionality
- `ReviewView.swift`: Results display UI
- `OpenAIService.swift`: OpenAI API integration
- `OutfitReview.swift`: Data models
- `Configuration.plist`: API key storage
- `config.swift`: Configuration management

### 3. File Details

#### full_length_mirrorApp.swift
- Entry point for the SwiftUI application
- Sets up the main app structure
- Initializes ContentView as the root view
- Minimal and focused on app bootstrapping

#### ContentView.swift
- Heart of the UI implementation
- Manages camera integration using AVFoundation
- Handles photo capture and library selection
- Implements loading states and error handling
- Coordinates with OpenAIService for analysis
- Manages navigation to ReviewView
- Key components:
  - CameraView: Custom UIViewRepresentable for camera
  - Photo picker integration
  - Loading and error overlays
  - Permission handling

#### Configuration.plist & config.swift
- Configuration.plist: Secure storage for OpenAI API key
- config.swift: Swift wrapper for accessing configuration
- Implements safe API key retrieval
- Fatal error handling for missing configuration

#### OpenAIService.swift
- Handles all OpenAI API communication
- Implements sophisticated prompt engineering
- Manages image conversion and API requests
- Features:
  - Base64 image encoding
  - Structured JSON response handling
  - Error handling and logging
  - Detailed prompt construction for outfit analysis
  - Token usage monitoring

#### OutfitReview.swift
- Defines core data models
- Key structures:
  - ReviewParameter: Individual score component
  - OutfitReview: Complete review container
  - OpenAIRequestPayload: API request structure
- Implements Codable for JSON handling
- Supports complex content types (text/image)

#### ReviewView.swift
- Displays analysis results
- Beautiful, card-based UI design
- Features:
  - Image display
  - Score visualization with color coding
  - Sectioned review display
  - Responsive layout
- Components:
  - ReviewSection: Reusable score display
  - Dynamic color coding based on scores
  - Support for decimal scores

### Important Callouts

1. **Security:**
   - API key stored in Configuration.plist
   - Secure key retrieval implementation

2. **Error Handling:**
   - Comprehensive error states in OpenAIService
   - User-friendly error messages
   - Graceful fallbacks

3. **Performance:**
   - Efficient image compression
   - Background processing for API calls
   - Optimized camera handling

4. **UX Considerations:**
   - Loading states
   - Permission handling
   - Error feedback
   - Intuitive navigation

5. **Code Organization:**
   - Clear separation of concerns
   - Modular components
   - Reusable structures
   - SwiftUI best practices

### Post Commit c1818a4

#### 1. Product Summary

**Full Length Mirror** is an iOS application designed to help users evaluate their outfits before stepping out. It offers real-time camera capture, photo library integration, and AI-powered outfit analysis using OpenAI's GPT-4.1-mini. The app provides a detailed scoring system for fit, color, and step-out readiness, all presented in a beautiful UI with instant feedback.

**User Journey:**
1. User opens the app and sees the camera view.
2. Options to:
   - Take a photo using the camera.
   - Select an existing photo from the library.
3. The app sends the image to OpenAI for analysis.
4. Receives a detailed outfit review with scores and comments.
5. Views a breakdown of fit, color, and step-out readiness scores.

#### 2. Project Summary

**Core Files:**
- `full_length_mirrorApp.swift`: Main app entry point, initializes `SnapsManager` and sets up `ContentView`.
- `ContentView.swift`: Manages the main UI and camera functionality, including photo capture and library selection.
- `ReviewView.swift`: Displays analysis results with a card-based UI design.
- `OpenAIService.swift`: Handles OpenAI API communication, including image conversion and API requests.
- `OutfitReview.swift`: Defines core data models for outfit reviews.
- `Configuration.plist`: Stores the API key securely.
- `config.swift`: Manages configuration access.

#### 3. File Details

**full_length_mirrorApp.swift**
- Entry point for the SwiftUI application.
- Initializes `SnapsManager` and sets `ContentView` as the root view.

**ContentView.swift**
- Manages camera integration using AVFoundation.
- Handles photo capture and library selection.
- Implements loading states and error handling.
- Coordinates with `OpenAIService` for analysis.
- Manages navigation to `ReviewView` and `CreditView`.

**OpenAIService.swift**
- Handles all OpenAI API communication.
- Implements sophisticated prompt engineering.
- Manages image conversion and API requests.
- Features error handling and logging.

**OutfitReview.swift**
- Defines core data models for outfit reviews.
- Implements `Codable` for JSON handling.

**ReviewView.swift**
- Displays analysis results with a card-based UI design.
- Features score visualization with color coding.

### Important Callouts

1. **Security:**
   - API key stored in `Configuration.plist`.
   - Secure key retrieval implementation.

2. **Error Handling:**
   - Comprehensive error states in `OpenAIService`.
   - User-friendly error messages.

3. **Performance:**
   - Efficient image compression.
   - Background processing for API calls.

4. **UX Considerations:**
   - Loading states.
   - Permission handling.
   - Error feedback.
   - Intuitive navigation.

5. **Code Organization:**
   - Clear separation of concerns.
   - Modular components.
   - Reusable structures.
   - SwiftUI best practices 