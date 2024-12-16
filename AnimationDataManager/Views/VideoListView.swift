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
    
    @State private var showUploadAlert = false
    @State private var alertMessage = ""
    @State private var isUploading = false
    @State private var showSuccess = false

    var body: some View {
        ZStack {
            VStack {
                if navigateToNextPage {
                    CompressionOptionsView(navigateBack: $navigateToNextPage)
                } else {
                    VStack {
                        HStack {
                            Spacer()
                            VideoListContent(thumbnailImage: $capturedThumbnailClass.thumb, player1: $player1, player2: $player2)
                                .frame(width: 700)
                            Spacer()
                            CompressionSection(compressionOptions: $compressionOptions, player1: $player1, player2: $player2)
                                .frame(width: 250)
                                .shadow(radius: 100)
                                .padding(70)
                            Spacer()
                        }
                        Spacer()
                        HStack {
                            Spacer()
                            UploadButton(action: uploadVideos)
                            BackButton(navigateBack: $navigateBack)
                            Spacer()
                        }
                    }
                    LogView()
                        .frame(width: 1200, height: 50)
                }
            }
            .padding()
        
        if isUploading {
            UploadProgressView(showSuccess: $showSuccess)
                .frame(width: 100, height: 100)
                .background(Color.black.opacity(0.9))
                .cornerRadius(10)
                .shadow(radius: 10)
        }
    }
    .alert(isPresented: $showUploadAlert) {
        Alert(
            title: Text("Upload Status"),
            message: Text(alertMessage),
            dismissButton: .default(Text("OK"))
        )
    }
}

    private func uploadVideos() {
        videoInfos.videoInfo1!.isEdited = editedStatus.isEdited1
        videoInfos.videoInfo2!.isEdited = editedStatus.isEdited2
        
        guard let videoInfo1 = videoInfos.videoInfo1 else {
            LogManager.shared.log("Video info 1 is not available")
            return
        }

        guard let videoInfo2 = videoInfos.videoInfo2 else {
            LogManager.shared.log("Video info 2 is not available")
            return
        }

        guard let thumbnailData = compressThumbnail(image: capturedThumbnailClass.thumb) else {
            LogManager.shared.log("Thumbnail data is not available or could not be compressed")
            return
        }

        guard let compressedVideoData = videoCompressedPreview.compressedVideoData else {
            LogManager.shared.log("Compressed video data is not available")
            return
        }

        isUploading = true
        showSuccess = false
        
        CouchDBManager.shared.uploadVideoPair(
            videoInfo1: videoInfo1,
            videoInfo2: videoInfo2,
            thumbnailData: thumbnailData,
            compressedVideoData: compressedVideoData
        ) { success, errorMessage in
            DispatchQueue.main.async {
                self.isUploading = false
                self.showSuccess = success
                self.alertMessage = success ? "Videos uploaded successfully" : "Failed to upload videos: \(errorMessage ?? "Unknown error")"
                self.showUploadAlert = !success
                
                if success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.showSuccess = false
                    }
                }
            }
        } progressHandler: { bytesUploaded, totalBytes in
            // Handle upload progress if needed
        }
    }
}
    
    private func compressThumbnail(image: NSImage?) -> Data? {
        guard let image = image, let tiffData = image.tiffRepresentation,
              let bitmapImageRep = NSBitmapImageRep(data: tiffData) else {
            LogManager.shared.log("Failed to get bitmap representation of the image")
            return nil
        }
        
        let properties: [NSBitmapImageRep.PropertyKey: Any] = [.compressionFactor: 0.7]
        var jpegData = bitmapImageRep.representation(using: .jpeg, properties: properties)
        
        LogManager.shared.log("Initial compression factor: 0.7, Data size: \(jpegData?.count ?? 0) bytes")
        
        // If initial compression is larger than maxSize, further reduce quality
        let maxSize = 1_000_000 // 1MB
        var compressionFactor = 0.7
        while let data = jpegData, data.count > maxSize, compressionFactor > 0.1 {
            compressionFactor -= 0.1
            jpegData = bitmapImageRep.representation(using: .jpeg, properties: [.compressionFactor: compressionFactor])
            LogManager.shared.log("Adjusted compression factor: \(compressionFactor), Data size: \(jpegData?.count ?? 0) bytes")
        }
        
        return jpegData
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
                Spacer()
            }
            if let thumbnail = thumbnailImage {
                ThumbnailView(thumbnail: thumbnail, retryAction: captureThumbnail, downloadAction: downloadThumbnail)
                Spacer()
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
            LogManager.shared.log("Player is not initialized")
            return
        }
        let asset = player.currentItem?.asset as? AVURLAsset
        let imageGenerator = AVAssetImageGenerator(asset: asset!)
        imageGenerator.appliesPreferredTrackTransform = true

        let time = player.currentTime()
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let image = NSImage(cgImage: cgImage, size: .zero)
            
            // Compress the thumbnail
            if let compressedThumbnail = compressThumbnail(image: image) {
                thumbnailImage = NSImage(data: compressedThumbnail)
                LogManager.shared.log("Thumbnail captured and compressed successfully")
            } else {
                LogManager.shared.log("Failed to compress thumbnail")
            }
        } catch {
            LogManager.shared.log("Failed to capture thumbnail: \(error)")
        }
    }
    
    private func compressThumbnail(image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImageRep = NSBitmapImageRep(data: tiffData) else {
            LogManager.shared.log("Failed to get bitmap representation of the image")
            return nil
        }
        
        let properties: [NSBitmapImageRep.PropertyKey: Any] = [.compressionFactor: 0.7]
        var jpegData = bitmapImageRep.representation(using: .jpeg, properties: properties)
        
        LogManager.shared.log("Initial compression factor: 0.7, Data size: \(jpegData?.count ?? 0) bytes")
        
        // If initial compression is larger than maxSize, further reduce quality
        let maxSize = 1_000_000 // 1MB
        var compressionFactor = 0.7
        while let data = jpegData, data.count > maxSize, compressionFactor > 0.1 {
            compressionFactor -= 0.1
            jpegData = bitmapImageRep.representation(using: .jpeg, properties: [.compressionFactor: compressionFactor])
            LogManager.shared.log("Adjusted compression factor: \(compressionFactor), Data size: \(jpegData?.count ?? 0) bytes")
        }
        
        return jpegData
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
            Text("Data Saving")
                .font(.headline)
                .padding(.bottom)

            CompressionOptionsForm(options: $compressionOptions, duration: getVideoInfo()?.duration ?? 0)

            Button(action: compressVideo) {
                Label("Compress Save", systemImage: "arrow.down.circle.fill")
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
            LogManager.shared.log("Video URL or Player is not available")
            return
        }

        let asset = AVURLAsset(url: url)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: compressionOptions.preset) else {
            LogManager.shared.log("Failed to create export session")
            return
        }

        exportSession.outputFileType = .mp4

        let panel = NSSavePanel()
        panel.allowedFileTypes = ["mp4"]
        panel.nameFieldStringValue = "compressed_video.mp4"
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
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
                            LogManager.shared.log("Compression completed and saved to \(exportURL)")
                        } catch {
                            LogManager.shared.log("Failed to read compressed video data: \(error)")
                        }
                    } else if let error = exportSession.error {
                        LogManager.shared.log("Failed to compress video: \(error)")
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
            Spacer()
            Image(nsImage: thumbnail)
                .resizable()
                .scaledToFit()
                .cornerRadius(5)
                .shadow(radius: 10)
                .frame(width: 300, height: 200)
            HStack {
                Button(action: retryAction) {
                    Label("Retry Capture", systemImage: "arrow.triangle.2.circlepath.camera.fill")
                }
                .buttonStyle(CustomButtonStyle(color: .indigo))
                Button(action: downloadAction) {
                    Label("Save", systemImage: "arrow.down.circle.fill")
                }
                .buttonStyle(CustomButtonStyle(color: .black.opacity(0.7)))
            }
            Spacer()
        }
        .frame(width: 300)
    }
}

struct UploadProgressView: View {
    @Binding var showSuccess: Bool
    @State private var rotateAnimation = false

    var body: some View {
        VStack {
            if showSuccess {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.green)
                Text("Upload Successful")
                    .font(.headline)
                    .foregroundColor(.green)
            } else {
                ZStack {
                    Circle()
                        .trim(from: 0.0, to: 0.5)
                        .stroke(lineWidth: 2)
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(rotateAnimation ? 360 : 0))
                        .frame(width: 38, height: 38)
                        .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
                        .onAppear {
                            rotateAnimation = true
                        }
                    
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                }
                Text("Uploading...")
                    .font(.headline)
            }
        }
        .padding()
        .background(Color.black.opacity(0.9))
        .cornerRadius(10)    }
}
