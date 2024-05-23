//
//  AnimationDataManagerApp.swift
//  AnimationDataManager
//
//  Created by harsh  on 16/05/24.
//

import SwiftUI

@main
struct AnimationDataManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 1.0))
                .environmentObject(SelectedFileURLs())
                .environmentObject(CapturedThumbnailClass())
                .environmentObject(VideoCompressedPreview())
                .environmentObject(EditedStatus())
                .environmentObject(VideoInfos())

        }
    }
}
