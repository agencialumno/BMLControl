import Foundation
import SwiftData

@Model
final class HourlyVitalSample {
    @Attribute(.unique) var sampleID: String // Formato: "YYYY-MM-DD-HH"
    var dateKey: String // Formato: "YYYY-MM-DD"
    var timestamp: Date
    var hour: Int
    var cumulativeSteps: Int
    var cumulativeCalories: Int
    var heartRate: Int
    var spo2: Int
    var systolicBP: Int
    var diastolicBP: Int

    init(
        sampleID: String,
        dateKey: String,
        timestamp: Date,
        hour: Int,
        cumulativeSteps: Int = 0,
        cumulativeCalories: Int = 0,
        heartRate: Int = 0,
        spo2: Int = 0,
        systolicBP: Int = 0,
        diastolicBP: Int = 0
    ) {
        self.sampleID = sampleID
        self.dateKey = dateKey
        self.timestamp = timestamp
        self.hour = hour
        self.cumulativeSteps = cumulativeSteps
        self.cumulativeCalories = cumulativeCalories
        self.heartRate = heartRate
        self.spo2 = spo2
        self.systolicBP = systolicBP
        self.diastolicBP = diastolicBP
    }
}