import SwiftUI
import AVKit
import AppKit

import Foundation

class VideoData: ObservableObject {
    @Published var videoURL: URL?
}



struct VideoPicker: NSViewRepresentable {
    @Binding var videoURL: URL?

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(title: "Select Video", target: context.coordinator, action: #selector(context.coordinator.openPanel))
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        let parent: VideoPicker

        init(_ parent: VideoPicker) {
            self.parent = parent
        }

        @objc func openPanel() {
            let panel = NSOpenPanel()
            panel.allowedFileTypes = ["mp4", "mov"]
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            if panel.runModal() == .OK {
                parent.videoURL = panel.url
            }
        }
    }
}


struct ContentView: View {
    @EnvironmentObject var videoData: VideoData

    var body: some View {
        VStack {
            if let videoURL = videoData.videoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 400)
            } else {
                Text("No video selected")
                    .foregroundColor(.gray)
            }
            
            VideoPicker(videoURL: $videoData.videoURL)
                .padding()
            
            Button(action: {
                if let url = videoData.videoURL {
                    print("Video URL: \(url.absoluteString)")
                } else {
                    print("No video URL available.")
                }
            }) {
                Text("Print Video URL")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .frame(width: 800, height: 600)
    }
}
