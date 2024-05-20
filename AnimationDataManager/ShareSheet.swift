//
//  ShareSheet.swift
//  AnimationDataManager
//
//  Created by harsh  on 17/05/24.
//

import SwiftUI

struct ShareSheet: NSViewRepresentable {
    var activityItems: [Any]

    func makeNSView(context: Context) -> NSView {
        let button = NSButton()
        button.title = "Share"
        button.target = context.coordinator
        button.action = #selector(Coordinator.share)
        return button
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: ShareSheet

        init(_ parent: ShareSheet) {
            self.parent = parent
        }

        @objc func share() {
            let picker = NSSharingServicePicker(items: parent.activityItems)
            if let button = NSApp.keyWindow?.contentView?.subviews.first(where: { $0 is NSButton }) {
                picker.show(relativeTo: .zero, of: button, preferredEdge: .minY)
            }
        }
    }
}
