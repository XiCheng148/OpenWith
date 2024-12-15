import SwiftUI

struct Toast: View {
    let message: String
    let isShowing: Bool
    
    var body: some View {
        Text(message)
            .font(.system(size: 13))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(Color.black.opacity(0.75))
            }
            .opacity(isShowing ? 1 : 0)
            .scaleEffect(isShowing ? 1 : 0.8)
            .animation(.spring(response: 0.3), value: isShowing)
    }
} 