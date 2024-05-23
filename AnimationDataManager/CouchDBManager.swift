import Foundation
import AVKit

class CouchDBManager: ObservableObject {
    static let shared = CouchDBManager()
    @Published var showAlert = false
    @Published var alertMessage = ""
    private let databaseName = "mydatabase"
    private let couchDBBaseURL = "http://127.0.0.1:5984"
    private let username = "admin"
    private let password = "adminadmin"

    func uploadVideoPair(videoInfo1: VideoInfo, videoInfo2: VideoInfo, thumbnailData: Data, compressedVideoData: Data, completion: @escaping (Bool, String?) -> Void, progressHandler: @escaping (Int64, Int64) -> Void) {
        let document = CouchDBDocument(video1: videoInfo1, video2: videoInfo2)
        guard let documentData = try? JSONEncoder().encode(document) else {
            print("Error encoding document")
            completion(false, "Error encoding document")
            return
        }

        var request = URLRequest(url: URL(string: "\(couchDBBaseURL)/\(databaseName)")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let credentials = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
        request.addValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        request.httpBody = documentData

        print("Uploading document metadata to CouchDB")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error uploading document metadata: \(error)")
                completion(false, error.localizedDescription)
                return
            }

            guard let data = data else {
                print("No data received from CouchDB")
                completion(false, "No data received from CouchDB")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response status code: \(httpResponse.statusCode)")
            }

            if let responseData = try? JSONDecoder().decode(CouchDBCreateResponse.self, from: data) {
                print("Document metadata uploaded successfully. Document ID: \(responseData.id), Rev: \(responseData.rev)")
                self.uploadVideoAttachments(documentID: responseData.id, videoInfo1: videoInfo1, videoInfo2: videoInfo2, rev: responseData.rev, thumbnailData: thumbnailData, compressedVideoData: compressedVideoData, completion: completion, progressHandler: progressHandler)
            } else {
                print("Error decoding response data")
                completion(false, "Error decoding response data")
            }
        }
        task.resume()
    }

    private func uploadVideoAttachments(documentID: String, videoInfo1: VideoInfo, videoInfo2: VideoInfo, rev: String, thumbnailData: Data, compressedVideoData: Data, completion: @escaping (Bool, String?) -> Void, progressHandler: @escaping (Int64, Int64) -> Void) {
        print("Uploading first video attachment")
        uploadVideoAttachment(documentID: documentID, rev: rev, videoInfo: videoInfo1, progressHandler: progressHandler) { success, newRev in
            guard success, let newRev = newRev else {
                print("Failed to upload first video attachment")
                completion(false, "Failed to upload first video attachment")
                return
            }
            print("First video attachment uploaded. Rev: \(newRev)")
            
            print("Uploading second video attachment")
            self.uploadVideoAttachment(documentID: documentID, rev: newRev, videoInfo: videoInfo2, progressHandler: progressHandler) { success, newRev in
                guard success, let newRev = newRev else {
                    print("Failed to upload second video attachment")
                    completion(false, "Failed to upload second video attachment")
                    return
                }
                print("Second video attachment uploaded. Rev: \(newRev)")
                
                print("Uploading thumbnail attachment")
                self.uploadAttachment(documentID: documentID, rev: newRev, attachmentName: "thumbnail.jpg", attachmentData: thumbnailData, mimeType: "image/jpeg") { success, newRev in
                    guard success, let newRev = newRev else {
                        print("Failed to upload thumbnail attachment")
                        completion(false, "Failed to upload thumbnail attachment")
                        return
                    }
                    print("Thumbnail attachment uploaded. Rev: \(newRev)")
                    
                    print("Uploading compressed video attachment")
                    self.uploadAttachment(documentID: documentID, rev: newRev, attachmentName: "compressed_video.mp4", attachmentData: compressedVideoData, mimeType: "video/mp4") { success, _ in
                        if success {
                            print("Compressed video attachment uploaded successfully")
                            completion(true, nil)
                        } else {
                            print("Failed to upload compressed video attachment")
                            completion(false, "Failed to upload compressed video attachment")
                        }
                    }
                }
            }
        }
    }

    private func uploadVideoAttachment(documentID: String, rev: String, videoInfo: VideoInfo, progressHandler: @escaping (Int64, Int64) -> Void, completion: @escaping (Bool, String?) -> Void) {
        var request = URLRequest(url: URL(string: "\(couchDBBaseURL)/\(databaseName)/\(documentID)/\(videoInfo.fileName)?rev=\(rev)")!)
        request.httpMethod = "PUT"
        request.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        let credentials = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
        request.addValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")

        print("Uploading video attachment: \(videoInfo.fileName)")
        let task = URLSession.shared.uploadTask(with: request, fromFile: videoInfo.fileURL) { data, response, error in
            if let error = error {
                print("Error uploading video attachment: \(error)")
                completion(false, error.localizedDescription)
                return
            }

            guard let data = data else {
                print("No data received from CouchDB")
                completion(false, "No data received from CouchDB")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response status code: \(httpResponse.statusCode)")
            }

            if let responseData = try? JSONDecoder().decode(CouchDBCreateResponse.self, from: data) {
                print("Video attachment uploaded successfully. Rev: \(responseData.rev)")
                completion(true, responseData.rev)
            } else {
                print("Error decoding response data")
                completion(false, "Error decoding response data")
            }
        }
        task.resume()
    }

    private func uploadAttachment(documentID: String, rev: String, attachmentName: String, attachmentData: Data, mimeType: String, completion: @escaping (Bool, String?) -> Void) {
        var request = URLRequest(url: URL(string: "\(couchDBBaseURL)/\(databaseName)/\(documentID)/\(attachmentName)?rev=\(rev)")!)
        request.httpMethod = "PUT"
        request.addValue(mimeType, forHTTPHeaderField: "Content-Type")
        let credentials = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
        request.addValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        request.httpBody = attachmentData

        print("Uploading attachment: \(attachmentName)")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error uploading attachment: \(error)")
                completion(false, error.localizedDescription)
                return
            }

            guard let data = data else {
                print("No data received from CouchDB")
                completion(false, "No data received from CouchDB")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response status code: \(httpResponse.statusCode)")
            }

            if let responseData = try? JSONDecoder().decode(CouchDBCreateResponse.self, from: data) {
                print("Attachment uploaded successfully. Rev: \(responseData.rev)")
                completion(true, responseData.rev)
            } else {
                print("Error decoding response data")
                completion(false, "Error decoding response data")
            }
        }
        task.resume()
    }
}

struct VideoInfo: Identifiable, Codable {
    var id = UUID()
    var fileURL: URL
    var fileName: String
    var duration: Double
    var fps: Float
    var resolution: String
    var codec: String
    var fileSize: Int64
    var isEdited: Bool
}

struct CouchDBDocument: Identifiable, Codable {
    var id: UUID
    var video1: VideoInfo
    var video2: VideoInfo

    init(video1: VideoInfo, video2: VideoInfo) {
        self.id = UUID()
        self.video1 = video1
        self.video2 = video2
    }
}

struct CouchDBCreateResponse: Codable {
    var ok: Bool
    var id: String
    var rev: String
}

struct CouchDBFetchResponse: Codable {
    var rows: [Row]

    struct Row: Codable {
        var doc: CouchDBDocument?
    }
}


//environement
class SelectedFileURLs: ObservableObject {
    @Published var selectedFileURL1: URL?
    @Published var selectedFileURL2: URL?
    
}
//environement thumbnail
class CapturedThumbnailClass: ObservableObject{
    @Published var thumb: NSImage?
}
//environment compressed video
class VideoCompressedPreview: ObservableObject {
    @Published var compressedVideoData: Data?
}

class EditedStatus: ObservableObject {
    @Published var isEdited1: Bool = false
    @Published var isEdited2: Bool = false
}

class VideoInfos: ObservableObject {
    @Published var videoInfo1: VideoInfo?
    @Published var videoInfo2: VideoInfo?
}
