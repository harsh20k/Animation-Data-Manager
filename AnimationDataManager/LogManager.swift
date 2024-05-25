import Foundation

class LogManager: ObservableObject {
    static let shared = LogManager()
    @Published var logMessages: [String] = []

    func log(_ message: String) {
        DispatchQueue.main.async {
            self.logMessages.append(message)
        }
    }
}
