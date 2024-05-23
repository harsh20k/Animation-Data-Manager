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



struct NextPageButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Next Page")
        }
        .buttonStyle(CustomButtonStyle(color: .orange))
    }
}


struct BackButton: View {
    @Binding var navigateBack: Bool

    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    navigateBack = false
                }
            }) {
                Text("Back")
            }
            .buttonStyle(CustomButtonStyle(color: .orange))
            Spacer()
        }
        .padding()
    }
}

struct CaptureButton: View {
    let action: () -> Void

    var body: some View {
        HStack{
            Spacer()
            Button(action: action) {
                Text("Capture Thumbnail")
            }
            .buttonStyle(CustomButtonStyle(color: .cyan))
            .frame(width: 250)
            Spacer()
        }
    }
}

struct UploadButton: View {
    let action: () -> Void

    var body: some View {
        HStack{
            Button(action: action) {
                Text("Upload")
            }
            .buttonStyle(CustomButtonStyle(color: .blue))
        }
        .padding()
    }
}
