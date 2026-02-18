import SwiftUI

struct LoadingView: View {
    var body: some View {
        ProgressView()
            .controlSize(.regular)
            .tint(.white)
    }
}

#Preview {
    LoadingView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
}
