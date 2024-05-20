import SwiftUI
import AVKit

struct CompressionOptionsView: View {
    var videoInfo2: VideoInfo
    @Binding var navigateBack: Bool
    @State private var compressionOptions = CompressionOptions()
    @State private var player: AVPlayer?

    var body: some View {
        VStack {
            BackButton(navigateBack: $navigateBack)
            CompressionSection(videoInfo: videoInfo2, compressionOptions: $compressionOptions, player: $player)
            Spacer()
            Text("Compression Options Page")
                .font(.largeTitle)
                .padding()
        }
        .padding()
    }
}





//struct CompressionOptionsForm: View {
//    @Binding var options: CompressionOptions
//    var duration: Double
//
//    var body: some View {
//        Form {
//            Picker("Compression Level", selection: $options.level) {
//                Text("Low").tag(CompressionLevel.low)
//                Text("Medium").tag(CompressionLevel.medium)
//            }
//            .pickerStyle(SegmentedPickerStyle())
//            
//            Text("Estimated File Size: \(options.estimatedFileSize(for: duration)) MB")
//                .padding(.top)
//        }
//    }
//}

//struct CompressionOptions {
//    var level: CompressionLevel = .medium
//
//    var preset: String {
//        switch level {
//        case .low:
//            return AVAssetExportPreset640x480
//        case .medium:
//            return AVAssetExportPreset1280x720
//        }
//    }
//
//    func estimatedFileSize(for duration: Double) -> String {
//        let bitrate: Double
//        switch level {
//        case .low:
//            bitrate = 1_000_000 // 1 Mbps
//        case .medium:
//            bitrate = 2_500_000 // 2.5 Mbps
//        }
//        let sizeInBytes = bitrate * duration / 8
//        let sizeInMB = sizeInBytes / 1_048_576
//        return String(format: "%.2f", sizeInMB)
//    }
//}

enum CompressionLevel: String, CaseIterable, Identifiable {
    case low
    case medium

    var id: String { self.rawValue }
}
