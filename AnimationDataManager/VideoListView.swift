import SwiftUI
import AVKit


struct VideoListView: View {
    @Binding var videoInfo: VideoInfo?
    @Binding var navigateBack: Bool
    @State private var navigateToNextPage = false
   
    @State private var player: AVPlayer?
    @State private var compressionOptions = CompressionOptions()
    
    
    @EnvironmentObject var selectedFileURLs :SelectedFileURLs
    @EnvironmentObject var videoCompressedPreview :VideoCompressedPreview
    @EnvironmentObject var capturedThumbnailClass :CapturedThumbnailClass


    var body: some View {
        VStack {
            if navigateToNextPage {
                CompressionOptionsView(videoInfo: videoInfo, navigateBack: $navigateToNextPage)
            } else {
                VStack {
                    BackButton(navigateBack: $navigateBack)
                    HStack{
                        VideoList(videoInfo: videoInfo!, thumbnailImage: $capturedThumbnailClass.thumb, player: $player)
                        Spacer()
                        CompressionSection(videoInfo: videoInfo!, compressionOptions: $compressionOptions, player: $player)
                            .frame(width: 250)
                            .padding(50)

                    }
                    HStack{
                        UploadButton(action: uploadVideos)
                        NextPageButton(action: { navigateToNextPage = true })
                    }
                }
            }
        }
        .padding()
    }

    private func uploadVideos() {
        guard let videoInfo1 = videoInfo else {
            print("Video info is not available")
            return
        }
        
        let videoInfo2 = selectedFileURLs.selectedFileURL2.map {
            VideoInfo(
                fileURL: $0,
                fileName: $0.lastPathComponent,
                duration: 0,
                fps: 0,
                resolution: "",
                codec: "",
                fileSize: 0,
                isEdited: false
            )
        }
        
        guard let videoInfo2 = videoInfo2 else {
            print("Second video info is not available")
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



struct VideoList: View {
    var videoInfo: VideoInfo
    @Binding var thumbnailImage: NSImage?
    @Binding var player: AVPlayer?
    
    @EnvironmentObject var selectedFileURLs :SelectedFileURLs


    var body: some View {
        HStack {
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
        print (selectedFileURLs.selectedFileURL1?.absoluteString)
        print (selectedFileURLs.selectedFileURL2?.absoluteString)
        print (videoInfo.fileURL)
        return videoInfo.fileURL
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
        let tempFileURL = tempDirectory.appendingPathComponent("lvmdjfslsd23djf.mp4")


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
