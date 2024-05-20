//
//  PrettyToggleStyle.swift
//  AnimationDataManager
//
//  Created by harsh  on 17/05/24.
//

import SwiftUI

struct PrettyToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
//            Spacer()
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(configuration.isOn ? Color.green : Color.gray)
                .frame(width: 40, height: 20) // Smaller dimensions
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .shadow(radius: 1)
                        .padding(1.5)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(Animation.linear(duration: 0.1))
                )
                .onTapGesture { configuration.isOn.toggle() }
        }
        .padding(.horizontal)
    }
}
