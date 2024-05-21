import SwiftUI
import AVKit

struct VideoUploadView: View {
    @Binding var selectedFileURL: URL?
    @Binding var isEdited: Bool
    var isLeft: Bool = false
    @Binding var videoInfo: VideoInfo?
    @Binding var showingFilePicker: Bool
    @Binding var player: AVPlayer?
    var buttonText: String
    var resetOtherToggle: () -> Void

    var body: some View {
        VStack {
            Button(buttonText) {
                showingFilePicker = true
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(CustomButtonStyle(color:.white.opacity(0.1)))
            
            if let selectedFileURL = selectedFileURL {
                VideoPreviewView(url: selectedFileURL, player: $player)
//                    .padding(.bottom, 20)
            }

            
            if let videoInfo = videoInfo {
                VStack(alignment: .leading)
                {
                    displayVideoInfo(videoInfo)
                    VStack(alignment: isLeft ? .leading : .center) {
                        Toggle("Edited", isOn: $isEdited)
                            .onChange(of: isEdited) { oldValue, newValue in
                                if newValue { resetOtherToggle() }
                            }
                            .toggleStyle(PrettyToggleStyle()) // Custom pretty toggle style
                    }
                    .frame(maxWidth: .infinity, alignment: isLeft ? .trailing : .leading)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .shadow(radius: 5)
                .frame(maxWidth: .infinity)
            }

        }
        .padding()
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.movie],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedFileURL = url
                    loadVideoInformation(for: url)
                }
            case .failure(let error):
                print("Failed to select file: \(error.localizedDescription)")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func displayVideoInfo(_ info: VideoInfo) -> some View {
        VStack(alignment: isLeft ? .trailing : .leading) {
            Text("Duration: \(info.duration) seconds")
            Text("FPS: \(info.fps)")
            Text("Resolution: \(info.resolution)")
            Text("Codec: \(info.codec)")
            Text("File Size: \(formatBytes(info.fileSize))")
        }
        .font(.system(.body, design: .monospaced))
        .frame(maxWidth: .infinity, alignment: isLeft ? .trailing : .leading)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func loadVideoInformation(for url: URL) {
        let asset = AVURLAsset(url: url)
        asset.loadValuesAsynchronously(forKeys: ["duration", "tracks"]) {
            var error: NSError? = nil
            let durationStatus = asset.statusOfValue(forKey: "duration", error: &error)
            let tracksStatus = asset.statusOfValue(forKey: "tracks", error: &error)
            switch (durationStatus, tracksStatus) {
            case (.loaded, .loaded):
                let duration = CMTimeGetSeconds(asset.duration)
                if let track = asset.tracks(withMediaType: .video).first {
                    let fps = track.nominalFrameRate
                    let resolution = "\(Int(track.naturalSize.width)) x \(Int(track.naturalSize.height))"
                    let codecDescriptions = track.formatDescriptions.compactMap { formatDescription -> String in
                        let formatDescription = formatDescription as! CMFormatDescription
                        let codecType = CMFormatDescriptionGetMediaSubType(formatDescription).fourCharCodeString
                        return codecType
                    }
                    let codec = codecDescriptions.joined(separator: ", ")

                    let fileSize: Int64 = {
                        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                        return attributes?[.size] as? Int64 ?? 0
                    }()

                    let videoInfo = VideoInfo(
                        fileURL: url,
                        fileName: url.lastPathComponent,
                        duration: duration,
                        fps: fps,
                        resolution: resolution,
                        codec: codec,
                        fileSize: fileSize,
                        isEdited: isEdited
                    )

                    DispatchQueue.main.async {
                        self.videoInfo = videoInfo
                    }
                }
            case (.failed, _), (_, .failed):
                print("Failed to load video information: \(String(describing: error))")
            default:
                break
            }
        }
    }
}

extension FourCharCode {
    var fourCharCodeString: String {
        let bytes: [CChar] = [
            CChar((self >> 24) & 0xFF),
            CChar((self >> 16) & 0xFF),
            CChar((self >> 8) & 0xFF),
            CChar(self & 0xFF),
            0
        ]
        return String(cString: bytes)
    }
}


