import SwiftUI

struct VideoControls: View {
    var playVideos: () -> Void
    var clearSelections: () -> Void
    var navigateToNext: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            Button(action: navigateToNext) {
                Text("Next")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: playVideos) {
                Label("Play/Pause", systemImage: "playpause.fill")
            }
            .buttonStyle(CustomButtonStyle(color: .green))
            .padding()

            Button(action: clearSelections) {
                Label("Clear", systemImage: "xmark.circle.fill")
            }
            .buttonStyle(CustomButtonStyle(color: .red))
        }
    }
}
