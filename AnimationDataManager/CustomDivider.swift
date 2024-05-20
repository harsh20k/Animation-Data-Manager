//
//  CustomDivider.swift
//  AnimationDataManager
//
//  Created by harsh  on 17/05/24.
//

import SwiftUI

struct CustomDivider: View {
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.blue, Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 2, height: geometry.size.height * 0.7)
                    .shadow(color: Color.blue.opacity(0.7), radius: 10, x: 0, y: 0)
                    .mask(
                        VStack(spacing: 0) {
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.black]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 20)
                            Rectangle().fill(Color.black)
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black, Color.clear]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 20)
                        }
                    )
                Spacer()
            }
        }
        .frame(width: 2)
    }
}

struct CustomButtonStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                ZStack {
                    color

                    // Inner shadow
                    if configuration.isPressed {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black.opacity(0.65), lineWidth: 4)
                            .blur(radius: 4)
                            .offset(x: 2, y: 2)
                            .mask(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.black, Color.clear]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                    }
                }
            )
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 10)
    }
}

struct VideoDetailsView: View {
    var videoInfo: VideoInfo

    var body: some View {
        VStack(alignment: .leading) {
            Text("Filename: \(videoInfo.fileName)")
            Text("Duration: \(Int(videoInfo.duration)) seconds")
            Text("FPS: \(videoInfo.fps)")
            Text("Resolution: \(videoInfo.resolution)")
            Text("Codec: \(videoInfo.codec)")
            Text("File Size: \(formatBytes(videoInfo.fileSize))")
        }
        .font(.system(.body, design: .monospaced))
        .padding()
        .background(Color.clear.opacity(0.1))
        .cornerRadius(8)
        .shadow(radius: 5)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
