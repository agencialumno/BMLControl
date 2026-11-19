import Foundation
import SwiftData

@Model
final class DailyActivityRecord {
    @Attribute(.unique) var dateKey: String // Formato: "YYYY-MM-DD"
    var date: Date
    var steps: Int
    var calories: Int
    var stepGoal: Int
    var deepSleepMinutes: Int
    var lightSleepMinutes: Int
    var updatedAt: Date

    init(
        dateKey: String,
        date: Date,
        steps: Int = 0,
        calories: Int = 0,
        stepGoal: Int = 8000,
        deepSleepMinutes: Int = 0,
        lightSleepMinutes: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.dateKey = dateKey
        self.date = date
        self.steps = steps
        self.calories = calories
        self.stepGoal = stepGoal
        self.deepSleepMinutes = deepSleepMinutes
        self.lightSleepMinutes = lightSleepMinutes
        self.updatedAt = updatedAt
    }

    /// Distância estimada em quilômetros baseada no comprimento médio de passo (0.74m).
    var estimatedDistanceKm: Double {
        return (Double(steps) * 0.74) / 1000.0
    }

    var totalSleepMinutes: Int {
        return deepSleepMinutes + lightSleepMinutes
    }
}