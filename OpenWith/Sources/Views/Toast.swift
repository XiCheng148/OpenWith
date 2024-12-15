import SwiftUI

struct Toast: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 13))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(Color.black.opacity(0.8))
            }
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    Toast(message: "这是一条测试消息")
}