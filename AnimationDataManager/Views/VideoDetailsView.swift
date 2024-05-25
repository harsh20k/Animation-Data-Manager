import SwiftUI

struct VideoDetailsView: View {
    var videoInfo: VideoInfo

    var body: some View {
        VStack(alignment: .leading) {
            Text("Filename: \(videoInfo.fileName)")
            Text("Duration: \(Int(videoInfo.duration)) seconds")
            Text("FPS: \(videoInfo.fps)")
            Text("Resolution: \(videoInfo.resolution)")
            Text("Codec: \(videoInfo.codec)")
            Text("File Size: \(formatBytes(videoInfo.fileSize))")
        }
        .font(.system(.body, design: .monospaced))
        .padding()
        .background(Color.clear.opacity(0.1))
        .cornerRadius(8)
        .shadow(radius: 5)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
