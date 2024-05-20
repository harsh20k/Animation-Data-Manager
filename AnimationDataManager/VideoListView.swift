import SwiftUI
import AVKit

struct VideoListView: View {
    var videoInfo1: VideoInfo
    var videoInfo2: VideoInfo
    @Binding var navigateBack: Bool
    @State private var thumbnailImage: NSImage?
    @State private var player: AVPlayer?
    @State private var compressionOptions = CompressionOptions()

    var body: some View {
        VStack {
            BackButton(navigateBack: $navigateBack)
            VideoList(videoInfo1: videoInfo1, videoInfo2: videoInfo2, thumbnailImage: $thumbnailImage, player: $player)
            Spacer()
            CompressionSection(videoInfo: videoInfo2, compressionOptions: $compressionOptions, player: $player)
            UploadButton(action: uploadVideos)
        }
        .padding()
    }

    private func uploadVideos() {
        // Implement the upload logic here
    }
}

struct BackButton: View {
    @Binding var navigateBack: Bool

    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    navigateBack = false
                }
            }) {
                Text("Back")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            Spacer()
        }
        .padding()
    }
}

struct VideoList: View {
    var videoInfo1: VideoInfo
    var videoInfo2: VideoInfo
    @Binding var thumbnailImage: NSImage?
    @Binding var player: AVPlayer?

    var body: some View {
        List {
            if let url = getVideoURL() {
                VideoPlayerView(url: url, player: $player)
            }

            if let thumbnail = thumbnailImage {
                ThumbnailView(thumbnail: thumbnail, retryAction: captureThumbnail, downloadAction: downloadThumbnail)
            } else {
                CaptureButton(action: captureThumbnail)
            }
        }
    }

    private func getVideoURL() -> URL? {
        let url = videoInfo1.isEdited ? videoInfo1.fileURL : videoInfo2.fileURL
        return url
    }

    private func captureThumbnail() {
        guard let player = player else {
            print("Player is not initialized")
            return
        }
        let asset = player.currentItem?.asset as? AVURLAsset
        let imageGenerator = AVAssetImageGenerator(asset: asset!)
        imageGenerator.appliesPreferredTrackTransform = true

        let time = player.currentTime()
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let image = NSImage(cgImage: cgImage, size: .zero)
            thumbnailImage = image
            print("Thumbnail captured successfully")
        } catch {
            print("Failed to capture thumbnail: \(error)")
        }
    }

    private func downloadThumbnail() {
        guard let thumbnail = thumbnailImage else { return }

        let panel = NSSavePanel()
        panel.allowedFileTypes = ["jpg"]
        panel.nameFieldStringValue = "thumbnail.jpg"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                if let tiffData = thumbnail.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData),
                   let jpegData = bitmapImage.representation(using: .jpeg, properties: [:]) {
                    try? jpegData.write(to: url)
                }
            }
        }
    }
}

struct VideoPlayerView: View {
    let url: URL
    @Binding var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .frame(height: 300)
            .onAppear {
                player = AVPlayer(url: url)
            }
    }
}

struct ThumbnailView: View {
    let thumbnail: NSImage
    let retryAction: () -> Void
    let downloadAction: () -> Void

    var body: some View {
        VStack {
            Image(nsImage: thumbnail)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .padding()
            HStack {
                Button(action: retryAction) {
                    Text("Retry Capture")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button(action: downloadAction) {
                    Text("Download Thumbnail")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
}

struct CaptureButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Capture Thumbnail")
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}

struct UploadButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Upload")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}

struct CompressionSection: View {
    var videoInfo: VideoInfo
    @Binding var compressionOptions: CompressionOptions
    @Binding var player: AVPlayer?

    var body: some View {
        VStack {
            Text("Video Compression Options")
                .font(.headline)
                .padding(.bottom)

            CompressionOptionsForm(options: $compressionOptions, duration: videoInfo.duration)

            Button(action: compressVideo) {
                Text("Compress and Download")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.top)
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

        let panel = NSSavePanel()
        panel.allowedFileTypes = ["mp4"]
        panel.nameFieldStringValue = "compressed_video.mp4"
        panel.begin { response in
            if response == .OK, let exportURL = panel.url {
                exportSession.outputURL = exportURL
                exportSession.exportAsynchronously {
                    if exportSession.status == .completed {
                        print("Compression completed")
                    } else if let error = exportSession.error {
                        print("Failed to compress video: \(error)")
                    }
                }
            }
        }
    }
}
