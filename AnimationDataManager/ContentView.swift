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
    @State private var showShareSheet = false
    @State private var showCSVDataView = false
    @State private var csvData: String = ""
    @State private var player1: AVPlayer?
    @State private var player2: AVPlayer?

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: exportCSV) {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 20, height: 20)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(5)

            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            
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
                    Button(action: uploadVideos) {
                        Label("Upload", systemImage: "arrow.up.circle.fill")
                    }
                    .buttonStyle(CustomButtonStyle(color: .blue))

                    Button(action: playVideos) {
                        Label("Play", systemImage: "play.circle.fill")
                    }
                    .buttonStyle(CustomButtonStyle(color: .green))
                    .padding()
                    
                    // Clear button
                    Button(action: clearSelections) {
                        Label("Clear", systemImage: "xmark.circle.fill")
                    }
                    .buttonStyle(CustomButtonStyle(color: .red))
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
        .sheet(isPresented: $showShareSheet, content: {
            ShareSheet(activityItems: [csvData])
        })
        .sheet(isPresented: $showCSVDataView, content: {
            CSVDataView(csvData: csvData, showCSVDataView: $showCSVDataView)
        })
    }

    private func playVideos() {
        player1?.seek(to: .zero)
        player2?.seek(to: .zero)
        player1?.play()
        player2?.play()
    }

    private func exportCSV() {
        couchDBManager.fetchAllDocuments { documents in
            let csvString = self.generateCSV(from: documents)
            DispatchQueue.main.async {
                self.csvData = csvString
                self.showCSVDataView = true
            }
        }
    }

    private func generateCSV(from documents: [CouchDBDocument]) -> String {
        var csvText = "ID,FileName,Duration,FPS,Resolution,Codec,FileSize,IsEdited\n"

        for document in documents {
            let videoInfo1 = document.video1
            let videoInfo2 = document.video2

            csvText += "\(document.id),\(videoInfo1.fileName),\(videoInfo1.duration),\(videoInfo1.fps),\(videoInfo1.resolution),\(videoInfo1.codec),\(videoInfo1.fileSize),\(videoInfo1.isEdited)\n"
            csvText += "\(document.id),\(videoInfo2.fileName),\(videoInfo2.duration),\(videoInfo2.fps),\(videoInfo2.resolution),\(videoInfo2.codec),\(videoInfo2.fileSize),\(videoInfo2.isEdited)\n"
        }

        return csvText
    }

    private func uploadVideos() {
        guard let fileURL1 = selectedFileURL1, let fileURL2 = selectedFileURL2 else {
            alertMessage = "Both video files must be selected."
            showAlert = true
            return
        }

        let videoInfo1 = VideoInfo(
            fileURL: fileURL1,
            fileName: fileURL1.lastPathComponent,
            duration: self.videoInfo1?.duration ?? 0,
            fps: self.videoInfo1?.fps ?? 0,
            resolution: self.videoInfo1?.resolution ?? "",
            codec: self.videoInfo1?.codec ?? "",
            fileSize: self.videoInfo1?.fileSize ?? 0,
            isEdited: isEdited1
        )
        let videoInfo2 = VideoInfo(
            fileURL: fileURL2,
            fileName: fileURL2.lastPathComponent,
            duration: self.videoInfo2?.duration ?? 0,
            fps: self.videoInfo2?.fps ?? 0,
            resolution: self.videoInfo2?.resolution ?? "",
            codec: self.videoInfo2?.codec ?? "",
            fileSize: self.videoInfo2?.fileSize ?? 0,
            isEdited: isEdited2
        )

        isUploading = true
        uploadProgress = 0.0

        couchDBManager.uploadVideoPair(videoInfo1: videoInfo1, videoInfo2: videoInfo2) { success, errorMessage in
            DispatchQueue.main.async {
                isUploading = false
                if success {
                    alertMessage = "Videos uploaded successfully"
                } else {
                    alertMessage = "Failed to upload videos: \(errorMessage ?? "Unknown error")"
                }
                showAlert = true
            }
        } progressHandler: { bytesUploaded, totalBytes in
            DispatchQueue.main.async {
                uploadProgress = Double(bytesUploaded) / Double(totalBytes)
            }
        }
    }

    // Action for Clear button
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
