import SwiftUI
import AVKit

struct ThumbnailSelectorView: View {
    var videoURL: URL
    @Binding var selectedImage: NSImage?
    @State private var player: AVPlayer?
    @State private var currentFrame: NSImage?

    var body: some View {
        VStack {
            VideoPlayer(player: player)
                .onAppear {
                    print("ThumbnailSelectorView appeared, setting up player")
                    setupPlayer()
                }
                .frame(height: 200)

            if let frame = currentFrame {
                Image(nsImage: frame)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .border(Color.gray, width: 1)
            }

            HStack {
                Button(action: captureFrame) {
                    Text("Capture Frame")
                }
                .buttonStyle(CustomButtonStyle(color: .blue))

                Button(action: confirmSelection) {
                    Text("OK")
                }
                .buttonStyle(CustomButtonStyle(color: .green))

                Button(action: cancelSelection) {
                    Text("Cancel")
                }
                .buttonStyle(CustomButtonStyle(color: .red))
            }
        }
        .padding()
    }

    private func setupPlayer() {
        player = AVPlayer(url: videoURL)
        player?.play()
        print("Player set up with URL: \(videoURL)")
    }

    private func captureFrame() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        print("Capturing frame at time: \(currentTime.seconds)")
        generateThumbnail(at: currentTime)
    }

    private func confirmSelection() {
        print("Confirming selection")
        selectedImage = currentFrame
        NSApplication.shared.keyWindow?.close()
    }

    private func cancelSelection() {
        print("Cancelling selection")
        selectedImage = nil
        NSApplication.shared.keyWindow?.close()
    }

    private func generateThumbnail(at time: CMTime) {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            currentFrame = NSImage(cgImage: cgImage, size: .zero)
            print("Thumbnail generated successfully")
        } catch {
            print("Failed to generate thumbnail: \(error)")
        }
    }
}
