//
//  CSVDataView.swift
//  AnimationDataManager
//
//  Created by harsh  on 17/05/24.
//
import SwiftUI

struct CSVDataView: View {
    @Environment(\.presentationMode) var presentationMode
    var csvData: String
    @Binding var showCSVDataView: Bool

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.red)
                }
                .padding()
            }
            ScrollView {
                Text(csvData)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            Spacer()
            Button(action: saveCSV) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save CSV")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
    }

    private func saveCSV() {
        let fileName = "VideoInfo.csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvData.write(to: path, atomically: true, encoding: .utf8)
            let panel = NSSavePanel()
            panel.nameFieldStringValue = fileName
            panel.begin { result in
                if result == .OK, let url = panel.url {
                    do {
                        try FileManager.default.moveItem(at: path, to: url)
                    } catch {
                        print("Failed to save file: \(error)")
                    }
                }
            }
        } catch {
            print("Failed to write CSV file: \(error)")
        }
    }
}
