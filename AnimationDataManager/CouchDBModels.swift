import Foundation

struct VideoInfo: Codable {
    let fileName: String
    let fileSize: Int64
    let duration: Double
    let fileURL: URL?
    let isEdited: Bool
    let fps: Float
    let resolution: String
    let codec: String
}


struct CouchDBFetchResponse: Codable {
    let rows: [Row]

    struct Row: Codable {
        let doc: Doc

        struct Doc: Codable {
            let _id: String
            let _rev: String
            let video1: VideoInfo
            let video2: VideoInfo
            let thumbnail: String?
        }
    }
}
