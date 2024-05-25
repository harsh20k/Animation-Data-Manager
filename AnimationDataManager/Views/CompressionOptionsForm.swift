import SwiftUI
import AVKit

struct CompressionOptionsForm: View {
    @Binding var options: CompressionOptions
    let duration: Double // Duration of the video in seconds

    var body: some View {
        VStack {
            Picker("Quality", selection: $options.preset) {
                Text("Low (Approx: \(formatFileSize(options.lowBitrate * duration)))").tag(AVAssetExportPresetLowQuality)
                Text("Medium (Approx: \(formatFileSize(options.mediumBitrate * duration)))").tag(AVAssetExportPresetMediumQuality)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
        }
    }

    private func formatFileSize(_ size: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB] // Display in MB
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}

struct CompressionOptions {
    var preset: String = AVAssetExportPresetMediumQuality
    var lowBitrate: Double = 500_000 // 500 kbps
    var mediumBitrate: Double = 1_500_000 // 1.5 Mbps
}
