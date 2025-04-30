import SwiftUI

struct CreditView: View {
    @ObservedObject var snapsManager = SnapsManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Title
            Text("Outfit Snaps")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Remaining snaps count
            Text("\(snapsManager.remainingSnaps)")
                .font(.system(size: 80))
                .fontWeight(.bold)
            
            Text("snaps left")
                .font(.title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Back button
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Back to Camera")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .navigationBarHidden(true)
    }
} 