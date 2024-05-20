        VStack(alignment: .leading) {
            Text("Video 1 Details:")
                .font(.title2)
                .padding(.bottom, 1)
            VideoDetailsView(videoInfo: document.video1)

            Text("Video 2 Details:")
                .font(.title2)
                .padding(.top, 10)
                .padding(.bottom, 1)
            VideoDetailsView(videoInfo: document.video2)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .shadow(radius: 5)
        .frame(maxWidth: .infinity)
        
        
        
        
.shadow(color: isEdited ? Color.white.opacity(0.3) : Color.black.opacity(0.5), radius: isEdited ? 50 : 10)
        
        
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
