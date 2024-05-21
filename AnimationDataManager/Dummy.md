import SwiftUI
import AVKit

struct CompressionSection: View {
    var videoInfo: VideoInfo
    @Binding var compressionOptions: CompressionOptions
    @Binding var player: AVPlayer?
    @EnvironmentObject var videoCompressedPreview: VideoCompressedPreview

    var body: some View {
        VStack {
            Text("Video Compression Options")
                .font(.headline)
                .padding(.bottom)

            CompressionOptionsForm(options: $compressionOptions, duration: videoInfo.duration)

            Button(action: compressVideo) {
                Text("Compress and Download")
            }
            .buttonStyle(CustomButtonStyle(color: .green))
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(30)
    }

    private func compressVideo() {
        guard let url = videoInfo.fileURL as URL?,
              let player = player else {
            print("Video URL or Player is not available")
            return
        }

        let asset = AVURLAsset(url: url)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: compressionOptions.preset) else {
            print("Failed to create export session")
            return
        }

        exportSession.outputFileType = .mp4

        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("compressed_video.mp4")
        
        exportSession.outputURL = tempFileURL
        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                do {
                    let compressedData = try Data(contentsOf: tempFileURL)
                    DispatchQueue.main.async {
                        self.videoCompressedPreview.compressedVideoData = compressedData
                    }
                    print("Compression completed")
                } catch {
                    print("Failed to read compressed video data: \(error)")
                }
            } else if let error = exportSession.error {
                print("Failed to compress video: \(error)")
            }
        }
    }
}
