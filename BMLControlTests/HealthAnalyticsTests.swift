import XCTest
@testable import BMLControl

final class HealthAnalyticsTests: XCTestCase {
    func testDailyVitalAggregation() {
        let now = Date()
        let key = HealthAnalyticsEngine.dateKey(for: now)

        let s1 = HourlyVitalSample(
            sampleID: "\(key)-08",
            dateKey: key,
            timestamp: now,
            hour: 8,
            cumulativeSteps: 500,
            cumulativeCalories: 30,
            heartRate: 68,
            spo2: 99,
            systolicBP: 120,
            diastolicBP: 78
        )
        let s2 = HourlyVitalSample(
            sampleID: "\(key)-10",
            dateKey: key,
            timestamp: now,
            hour: 10,
            cumulativeSteps: 1400,
            cumulativeCalories: 80,
            heartRate: 82,
            spo2: 98,
            systolicBP: 126,
            diastolicBP: 80
        )

        let points = HealthAnalyticsEngine.buildVitalSeries(
            samples: [s1, s2],
            timeframe: .day,
            anchorDate: now
        )

        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points[0].avgHeartRate, 68)
        XCTAssertEqual(points[1].avgHeartRate, 82)
    }

    func testWeeklyActivitySeriesReturnsSevenDays() {
        let now = Date()
        let key = HealthAnalyticsEngine.dateKey(for: now)
        let todayRecord = DailyActivityRecord(dateKey: key, date: now, steps: 4200, calories: 210)

        let series = HealthAnalyticsEngine.buildActivitySeries(
            dailyRecords: [todayRecord],
            hourlySamples: [],
            timeframe: .week,
            anchorDate: now
        )

        XCTAssertEqual(series.count, 7)
        XCTAssertEqual(series.last?.steps, 4200)
    }
}