//
//  CouchDBManager.swift
//  AnimationDataManager
//
//  Created by harsh  on 16/05/24.
//

import Foundation

class CouchDBManager: ObservableObject {
    static let shared = CouchDBManager()
    private let databaseName = "mydatabase"
    private let couchDBBaseURL = "http://127.0.0.1:5984"
    private let username = "admin"
    private let password = "adminadmin"

    func uploadVideoPair(videoInfo1: VideoInfo, videoInfo2: VideoInfo, completion: @escaping (Bool, String?) -> Void, progressHandler: @escaping (Int64, Int64) -> Void) {
        let document = CouchDBDocument(video1: videoInfo1, video2: videoInfo2)
        guard let documentData = try? JSONEncoder().encode(document) else {
            completion(false, nil)
            return
        }

        var request = URLRequest(url: URL(string: "\(couchDBBaseURL)/\(databaseName)")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let credentials = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
        request.addValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        request.httpBody = documentData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(false, nil)
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201,
               let responseData = try? JSONDecoder().decode(CouchDBCreateResponse.self, from: data) {
                self.uploadVideoAttachments(documentID: responseData.id, videoInfo1: videoInfo1, videoInfo2: videoInfo2, rev: responseData.rev, completion: completion, progressHandler: progressHandler)
            } else {
                completion(false, nil)
            }
        }
        task.resume()
    }

    private func uploadVideoAttachments(documentID: String, videoInfo1: VideoInfo, videoInfo2: VideoInfo, rev: String, completion: @escaping (Bool, String?) -> Void, progressHandler: @escaping (Int64, Int64) -> Void) {
        uploadVideoAttachment(documentID: documentID, rev: rev, videoInfo: videoInfo1, progressHandler: progressHandler) { success, newRev in
            guard success, let newRev = newRev else {
                completion(false, nil)
                return
            }
            self.uploadVideoAttachment(documentID: documentID, rev: newRev, videoInfo: videoInfo2, progressHandler: progressHandler, completion: completion)
        }
    }

    private func uploadVideoAttachment(documentID: String, rev: String, videoInfo: VideoInfo, progressHandler: @escaping (Int64, Int64) -> Void, completion: @escaping (Bool, String?) -> Void) {
        var request = URLRequest(url: URL(string: "\(couchDBBaseURL)/\(databaseName)/\(documentID)/\(videoInfo.fileName)?rev=\(rev)")!)
        request.httpMethod = "PUT"
        request.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        let credentials = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
        request.addValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.uploadTask(with: request, fromFile: videoInfo.fileURL) { data, response, error in
            guard let data = data, error == nil else {
                completion(false, nil)
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201,
               let responseData = try? JSONDecoder().decode(CouchDBCreateResponse.self, from: data) {
                completion(true, responseData.rev)
            } else {
                completion(false, nil)
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
