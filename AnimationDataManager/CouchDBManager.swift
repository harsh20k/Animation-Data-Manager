//
//  CouchDBManager.swift
//  AnimationDataManager
//
//  Created by harsh  on 16/05/24.
//

import Foundation
import SwiftUI

class CouchDBManager: ObservableObject {
    static let shared = CouchDBManager()
    @Published var documents: [CouchDBDocument] = []

    let databaseURL = URL(string: "http://127.0.0.1:5984/mydatabase")!
    let username = "admin"
    let password = "adminadmin"

    private init() {}

    private func createRequest(url: URL, method: String, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let loginString = "\(username):\(password)"
        let loginData = loginString.data(using: .utf8)!
        let base64LoginString = loginData.base64EncodedString()
        request.addValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }

    func insertDocument(document: CouchDBDocument) {
        guard let url = URL(string: "\(databaseURL)") else { return }
        let body: Data
        do {
            body = try JSONEncoder().encode(document)
        } catch {
            print("Error encoding document: \(error)")
            return
        }
        let request = createRequest(url: url, method: "POST", body: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error inserting document: \(error)")
                return
            }
            print("Document inserted")
        }
        task.resume()
    }

    func fetchDocuments() {
        guard let url = URL(string: "\(databaseURL)/_all_docs?include_docs=true") else { return }
        let request = createRequest(url: url, method: "GET")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching documents: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                let allDocsResponse = try JSONDecoder().decode(AllDocsResponse.self, from: data)
                DispatchQueue.main.async {
                    self.documents = allDocsResponse.rows.map { $0.doc }
                }
            } catch {
                print("Error decoding response: \(error)")
            }
        }
        task.resume()
    }
}

struct CouchDBDocument: Codable, Identifiable {
    var _id: String?
    var _rev: String?
    var name: String
    var age: Int

    var id: String { _id ?? UUID().uuidString }
}

struct AllDocsResponse: Codable {
    var rows: [Row]

    struct Row: Codable {
        var doc: CouchDBDocument
    }
}
