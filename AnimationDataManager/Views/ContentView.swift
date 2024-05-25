import SwiftUI
import AVKit

struct ContentView: View {
    @ObservedObject private var couchDBManager = CouchDBManager.shared
    @EnvironmentObject var selectedFileURLs: SelectedFileURLs
    @EnvironmentObject var editedStatus: EditedStatus
    @EnvironmentObject var videoInfos: VideoInfos
    @EnvironmentObject var capturedThumbnail: CapturedThumbnailClass
    @EnvironmentObject var compressedVideo: VideoCompressedPreview

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var showingFilePicker1 = false
    @State private var showingFilePicker2 = false
    @State private var player1: AVPlayer?
    @State private var player2: AVPlayer?
    @State private var navigateToNextPage = false

    var body: some View {
        VStack {
            if navigateToNextPage {
                if editedStatus.isEdited1 {
                    VideoListView(
                        navigateBack: $navigateToNextPage
                    )
                } else {
                    VideoListView(
                        navigateBack: $navigateToNextPage
                    )
                }
            } else {
                VStack {
                    HStack {
                        VideoUploadView(
                            selectedFileURL: $selectedFileURLs.selectedFileURL1,
                            isEdited: $editedStatus.isEdited1,
                            isLeft: true,
                            videoInfo: $videoInfos.videoInfo1,
                            showingFilePicker: $showingFilePicker1,
                            player: $player1,
                            buttonText: "First Video",
                            resetOtherToggle: { editedStatus.isEdited2 = false }
                        )

                        CustomDivider()

                        VideoUploadView(
                            selectedFileURL: $selectedFileURLs.selectedFileURL2,
                            isEdited: $editedStatus.isEdited2,
                            isLeft: false,
                            videoInfo: $videoInfos.videoInfo2,
                            showingFilePicker: $showingFilePicker2,
                            player: $player2,
                            buttonText: "Second Video",
                            resetOtherToggle: { editedStatus.isEdited1 = false }
                        )
                    }

                    if selectedFileURLs.selectedFileURL1 != nil && selectedFileURLs.selectedFileURL2 != nil {
                        HStack(spacing: 20) {
                            Button(action: playVideos) {
                                Label("Play/Pause", systemImage: "playpause.circle.fill")
                            }
                            .buttonStyle(CustomButtonStyle(color: .green))
                            .padding()

                            Button(action: clearSelections) {
                                Label("Clear", systemImage: "xmark.circle.fill")
                            }
                            .buttonStyle(CustomButtonStyle(color: .red))

                            Button(action: {
                                withAnimation {
                                    navigateToNextPage = true
                                }
                            }) {
                                Label("Next", systemImage: "arrowshape.forward.fill")
                            }
                            .buttonStyle(CustomButtonStyle(color: .orange))
                        }
                    }

                    if isUploading {
                        VStack {
                            ProgressView(value: uploadProgress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle())
                                .padding()
                            Text("Uploading... \(Int(uploadProgress * 100))%")
                        }
                        .padding()
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Notification"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
        }
    }

    private func playVideos() {
        if let player1 = player1, let player2 = player2 {
            if player1.timeControlStatus == .playing && player2.timeControlStatus == .playing {
                player1.pause()
                player2.pause()
            } else {
                player1.play()
                player2.play()
            }
        }
    }


    private func clearSelections() {
        selectedFileURLs.selectedFileURL1 = nil
        selectedFileURLs.selectedFileURL2 = nil
        editedStatus.isEdited1 = false
        editedStatus.isEdited2 = false
        videoInfos.videoInfo1 = nil
        videoInfos.videoInfo2 = nil
        player1 = nil
        player2 = nil
        capturedThumbnail.thumb = nil
        compressedVideo.compressedVideoData = nil
    }
}
