import SwiftUI
import AVKit

struct VideoListView: View {
    @Binding var navigateBack: Bool
    @State private var navigateToNextPage = false
    
    @EnvironmentObject var videoInfos: VideoInfos
    @EnvironmentObject var editedStatus: EditedStatus
    @EnvironmentObject var capturedThumbnailClass: CapturedThumbnailClass
    @EnvironmentObject var videoCompressedPreview: VideoCompressedPreview
    
    @State private var player1: AVPlayer?
    @State private var player2: AVPlayer?
    @State private var compressionOptions = CompressionOptions()

    var body: some View {
        VStack {
            if navigateToNextPage {
                CompressionOptionsView(navigateBack: $navigateToNextPage)
            } else {
                VStack {
                    BackButton(navigateBack: $navigateBack)
                    HStack {
                        VideoListContent(thumbnailImage: $capturedThumbnailClass.thumb, player1: $player1, player2: $player2)
                        Spacer()
                        CompressionSection(compressionOptions: $compressionOptions, player1: $player1, player2: $player2)
                            .frame(width: 250)
                            .padding(50)
                    }
                    HStack {
                        UploadButton(action: uploadVideos)
//                        NextPageButton(action: { navigateToNextPage = true })
                    }
                }
            }
        }
        .padding()
    }

    private func uploadVideos() {
        videoInfos.videoInfo1!.isEdited = editedStatus.isEdited1
        videoInfos.videoInfo2!.isEdited = editedStatus.isEdited2
        
        guard let videoInfo1 = videoInfos.videoInfo1 else {
            print("Video info 1 is not available")
            return
        }

        guard let videoInfo2 = videoInfos.videoInfo2 else {
            print("Video info 2 is not available")
            return
        }

        guard let thumbnailData = capturedThumbnailClass.thumb?.tiffRepresentation else {
            print("Thumbnail data is not available")
            return
        }

        guard let compressedVideoData = videoCompressedPreview.compressedVideoData else {
            print("Compressed video data is not available")
            return
        }

        
        CouchDBManager.shared.uploadVideoPair(
            videoInfo1: videoInfo1,
            videoInfo2: videoInfo2,
            thumbnailData: thumbnailData,
            compressedVideoData: compressedVideoData
        ) { success, errorMessage in
            DispatchQueue.main.async {
                CouchDBManager.shared.showAlert = true
                CouchDBManager.shared.alertMessage = success ? "Videos uploaded successfully" : "Failed to upload videos: \(errorMessage ?? "Unknown error")"
            }
        } progressHandler: { bytesUploaded, totalBytes in
            // Handle upload progress if needed
        }
    }
}

struct VideoListContent: View {
    @Binding var thumbnailImage: NSImage?
    @Binding var player1: AVPlayer?
    @Binding var player2: AVPlayer?
    
    @EnvironmentObject var videoInfos: VideoInfos
    @EnvironmentObject var editedStatus: EditedStatus

    var body: some View {
        HStack {
            if let url = getVideoURL() {
                VideoPlayerView(url: url, player: editedStatus.isEdited1 ? $player1 : $player2)
            }
            if let thumbnail = thumbnailImage {
                ThumbnailView(thumbnail: thumbnail, retryAction: captureThumbnail, downloadAction: downloadThumbnail)
            } else {
                CaptureButton(action: captureThumbnail)
            }
        }
    }

    private func getVideoURL() -> URL? {
        return editedStatus.isEdited1 ? videoInfos.videoInfo1?.fileURL : videoInfos.videoInfo2?.fileURL
    }

    private func captureThumbnail() {
        guard let player = editedStatus.isEdited1 ? player1 : player2 else {
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

struct CompressionSection: View {
    @Binding var compressionOptions: CompressionOptions
    @Binding var player1: AVPlayer?
    @Binding var player2: AVPlayer?
    @EnvironmentObject var videoInfos: VideoInfos
    @EnvironmentObject var videoCompressedPreview: VideoCompressedPreview
    @EnvironmentObject var editedStatus: EditedStatus

    var body: some View {
        VStack {
            Text("Video Compression Options")
                .font(.headline)
                .padding(.bottom)

            CompressionOptionsForm(options: $compressionOptions, duration: getVideoInfo()?.duration ?? 0)

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
            guard let videoInfo = editedStatus.isEdited1 ? videoInfos.videoInfo1 : videoInfos.videoInfo2,
                  let url = videoInfo.fileURL as URL?,
                  let player = editedStatus.isEdited1 ? player1 : player2 else {
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
                            do {
                                let compressedData = try Data(contentsOf: exportURL)
                                DispatchQueue.main.async {
                                    self.videoCompressedPreview.compressedVideoData = compressedData
                                }
                                print("Compression completed and saved to \(exportURL)")
                            } catch {
                                print("Failed to read compressed video data: \(error)")
                            }
                        } else if let error = exportSession.error {
                            print("Failed to compress video: \(error)")
                        }
                    }
                }
            }
        }

    private func getVideoInfo() -> VideoInfo? {
        return editedStatus.isEdited1 ? videoInfos.videoInfo1 : videoInfos.videoInfo2
    }
}

struct VideoPlayerView: View {
    let url: URL
    @Binding var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player = AVPlayer(url: url)
            }
            .cornerRadius(10)
            .shadow(radius: 10)
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
                .cornerRadius(5)
                .shadow(radius: 10)
                .frame(width: 200, height: 200)
                .padding()
            HStack {
                Button(action: retryAction) {
                    Text("Retry Capture")
                }
                .buttonStyle(CustomButtonStyle(color: .indigo))
                Button(action: downloadAction) {
                    Text("Download Thumbnail")
                }
                .buttonStyle(CustomButtonStyle(color: .indigo))
            }
        }
        .frame(width: 250)
    }
}
