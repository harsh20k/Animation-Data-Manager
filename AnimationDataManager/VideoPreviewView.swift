//
//  VideoPreviewView.swift
//  AnimationDataManager
//
//  Created by harsh  on 17/05/24.
//

//import SwiftUI
//import AVKit
//
//struct VideoPreviewView: View {
//    let url: URL
//
//    var body: some View {
//        VideoPlayer(player: AVPlayer(url: url))
//            .cornerRadius(10)
//            .shadow(radius: 10)
//            .padding(10)
//    }
//}

import SwiftUI
import AVKit

struct VideoPreviewView: View {
    let url: URL
    @Binding var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player = AVPlayer(url: url)
            }
            .cornerRadius(10)
            .padding(10) // Adjust the height as needed
    }
}
