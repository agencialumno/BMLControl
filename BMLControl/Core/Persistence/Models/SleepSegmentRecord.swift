import Foundation
import SwiftData

@Model
final class SleepSegmentRecord {
    @Attribute(.unique) var segmentID: String // Formato: "YYYY-MM-DD-HH-MM"
    var dateKey: String // Formato: "YYYY-MM-DD"
    var startTimestamp: Date
    var isDeepSleep: Bool
    var durationMinutes: Int

    init(
        segmentID: String,
        dateKey: String,
        startTimestamp: Date,
        isDeepSleep: Bool,
        durationMinutes: Int
    ) {
        self.segmentID = segmentID
        self.dateKey = dateKey
        self.startTimestamp = startTimestamp
        self.isDeepSleep = isDeepSleep
        self.durationMinutes = durationMinutes
    }
}