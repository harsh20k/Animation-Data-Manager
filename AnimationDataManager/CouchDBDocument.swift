import Foundation
import AVKit
import AppKit

class CouchDBDocument: Identifiable, Equatable {
    static func == (lhs: CouchDBDocument, rhs: CouchDBDocument) -> Bool {
        return lhs.id == rhs.id
    }

    var id: String
    var rev: String
    var video1: VideoInfo
    var video2: VideoInfo
    var thumbnail: NSImage?

    init(from doc: CouchDBFetchResponse.Row.Doc) {
        self.id = doc._id
        self.rev = doc._rev
        self.video1 = doc.video1
        self.video2 = doc.video2
        if let thumbnailData = Data(base64Encoded: doc.thumbnail ?? "") {
            self.thumbnail = NSImage(data: thumbnailData)
        }
    }

    func generateThumbnail() {
        let asset = AVAsset(url: video1.fileURL!)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            self.thumbnail = NSImage(cgImage: cgImage, size: .zero)
        } catch {
            print("Failed to generate thumbnail: \(error)")
        }
    }
}
