import SwiftUI

struct SnapsPillView: View {
    let count: Int
    
    var body: some View {
        Text(count <= 7 ? "\(count) snaps left" : "take a mirror selfie")
            .font(.body)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.7)) // 70% opacity for transparency
            )
    }
} 