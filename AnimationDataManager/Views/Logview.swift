import SwiftUI

struct LogView: View {
    @ObservedObject var logManager = LogManager.shared

    var body: some View {
        VStack {

            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(logManager.logMessages.reversed(), id: \.self) { message in
                        Text(message)
                            .monospaced()
                            .frame(maxWidth: .infinity) // Fix the width
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.black)
        .cornerRadius(5)
        .shadow(radius: 5)
        .frame(width: 1200) // Set a fixed width here
    }
}
