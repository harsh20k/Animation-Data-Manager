import SwiftUI
import AVKit

struct VideoPreviewView: View {
    let url: URL
    @Binding var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player = AVPlayer(url: url)
            }
            .cornerRadius(10)
            .padding(10) // Adjust the height as needed
    }
}
