import Foundation

struct BLELogEntry: Identifiable, Hashable {
    enum Direction: String {
        case info = "SYS"
        case tx = "TX ->"
        case rx = "<- RX"
        case error = "ERR"
    }

    let id = UUID()
    let timestamp: Date
    let direction: Direction
    let message: String

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}