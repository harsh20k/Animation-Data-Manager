import SwiftUI
import AVKit

struct VideoUploadSection: View {
    @Binding var selectedFileURL1: URL?
    @Binding var selectedFileURL2: URL?
    @Binding var isEdited1: Bool
    @Binding var isEdited2: Bool
    @Binding var videoInfo1: VideoInfo?
    @Binding var videoInfo2: VideoInfo?
    @Binding var showingFilePicker1: Bool
    @Binding var showingFilePicker2: Bool
    @Binding var player1: AVPlayer?
    @Binding var player2: AVPlayer?

    var body: some View {
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
    }
}
