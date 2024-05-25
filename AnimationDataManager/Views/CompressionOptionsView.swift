import SwiftUI
import AVKit

struct CompressionOptionsView: View {
    @Binding var navigateBack: Bool
    @State private var compressionOptions = CompressionOptions()
    @State private var player: AVPlayer?

    @EnvironmentObject var videoInfos: VideoInfos
    @EnvironmentObject var editedStatus: EditedStatus

    var body: some View {
        VStack {
            BackButton(navigateBack: $navigateBack)
            List {
                if let url = getVideoURL() {
                    VideoPlayerView(url: url, player: $player)
                }
            }
            CompressionSection(compressionOptions: $compressionOptions, player1: $player, player2: $player)
            Spacer()
            Text("Compression Options Page")
                .font(.largeTitle)
                .padding()
            LogView() // Add this line to display the logs

        }
        .padding()
    }

    private func getVideoURL() -> URL? {
        return editedStatus.isEdited1 ? videoInfos.videoInfo1?.fileURL : videoInfos.videoInfo2?.fileURL
    }
}

enum CompressionLevel: String, CaseIterable, Identifiable {
    case low
    case medium

    var id: String { self.rawValue }
}
