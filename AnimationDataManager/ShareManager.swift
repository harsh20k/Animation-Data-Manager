//
//  ShareManager.swift
//  AnimationDataManager
//
//  Created by harsh  on 17/05/24.
//

import Foundation
import AppKit

class ShareManager {
    static let shared = ShareManager()

    private init() {}

    func exportCSV(documents: [[String: Any]], completion: @escaping (URL?) -> Void) {
        let csvString = generateCSV(from: documents)
        let fileName = "VideoInfo.csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvString.write(to: path, atomically: true, encoding: .utf8)
            completion(path)
        } catch {
            print("Failed to write CSV file: \(error)")
            completion(nil)
        }
    }

    private func generateCSV(from documents: [[String: Any]]) -> String {
        var csvText = "Document\n"

        for document in documents {
            let jsonData = try? JSONSerialization.data(withJSONObject: document, options: .prettyPrinted)
            let jsonString = String(data: jsonData!, encoding: .utf8) ?? ""
            csvText += "\(jsonString)\n"
        }

        return csvText
    }
}
