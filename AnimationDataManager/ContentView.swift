import SwiftUI
import AVKit

struct ContentView: View {
    @ObservedObject private var couchDBManager = CouchDBManager.shared
    @State private var selectedFileURL1: URL?
    @State private var selectedFileURL2: URL?
    @State private var isEdited1: Bool = false
    @State private var isEdited2: Bool = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var videoInfo1: VideoInfo?
    @State private var videoInfo2: VideoInfo?
    @State private var showingFilePicker1 = false
    @State private var showingFilePicker2 = false
    @State private var player1: AVPlayer?
    @State private var player2: AVPlayer?
    @State private var navigateToNextPage = false

    var body: some View {
        VStack {
            if navigateToNextPage {
                VideoListView(
                    videoInfo1: videoInfo1!,
                    videoInfo2: videoInfo2!,
                    navigateBack: $navigateToNextPage
                )
            } else {
                VStack {
                    HStack {
                        VideoUploadView(
                            selectedFileURL: $selectedFileURL1,
                            isEdited: $isEdited1,
                            isLeft: true,
                            videoInfo: $videoInfo1,
                            showingFilePicker: $showingFilePicker1,
                            player: $player1,
                            buttonText: "First Video",
                            resetOtherToggle: { isEdited2 = false }
                        )
                        
                        CustomDivider()

                        VideoUploadView(
                            selectedFileURL: $selectedFileURL2,
                            isEdited: $isEdited2,
                            isLeft: false,
                            videoInfo: $videoInfo2,
                            showingFilePicker: $showingFilePicker2,
                            player: $player2,
                            buttonText: "Second Video",
                            resetOtherToggle: { isEdited1 = false }
                        )
                    }

                    if selectedFileURL1 != nil && selectedFileURL2 != nil {
                        HStack(spacing: 20) {
                            Button(action: playVideos) {
                                Label("Play", systemImage: "play.circle.fill")
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
                                Text("Next")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
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
        player1?.seek(to: .zero)
        player2?.seek(to: .zero)
        player1?.play()
        player2?.play()
    }

    private func clearSelections() {
        selectedFileURL1 = nil
        selectedFileURL2 = nil
        isEdited1 = false
        isEdited2 = false
        videoInfo1 = nil
        videoInfo2 = nil
        player1 = nil
        player2 = nil
    }
}
