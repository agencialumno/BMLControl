import Foundation

enum HealthTimeframe: String, CaseIterable, Identifiable {
    case day = "Dia"
    case week = "Semana"
    case month = "Mês"

    var id: String { rawValue }
}

struct VitalChartPoint: Identifiable, Equatable {
    let id: String
    let label: String
    let date: Date
    let avgHeartRate: Double
    let minHeartRate: Int
    let maxHeartRate: Int
    let avgSpO2: Double
    let minSpO2: Int
    let avgSystolic: Double
    let avgDiastolic: Double
    let sampleCount: Int
}

struct ActivityChartPoint: Identifiable, Equatable {
    let id: String
    let label: String
    let date: Date
    let steps: Int
    let calories: Int
    let distanceKm: Double
}

struct SleepChartPoint: Identifiable, Equatable {
    let id: String
    let label: String
    let date: Date
    let deepMinutes: Int
    let lightMinutes: Int

    var totalMinutes: Int { deepMinutes + lightMinutes }
}

enum HealthAnalyticsEngine {
    static func dateKey(for date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 2026, c.month ?? 1, c.day ?? 1)
    }

    static func shortDayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }

    static func periodTitle(for timeframe: HealthTimeframe, anchorDate: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")

        switch timeframe {
        case .day:
            if calendar.isDateInToday(anchorDate) { return "Hoje" }
            if calendar.isDateInYesterday(anchorDate) { return "Ontem" }
            formatter.dateFormat = "dd 'de' MMM"
            return formatter.string(from: anchorDate)
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: anchorDate) ?? anchorDate
            formatter.dateFormat = "dd/MM"
            return "\(formatter.string(from: start)) – \(formatter.string(from: anchorDate))"
        case .month:
            let start = calendar.date(byAdding: .day, value: -29, to: anchorDate) ?? anchorDate
            formatter.dateFormat = "dd/MM"
            return "\(formatter.string(from: start)) – \(formatter.string(from: anchorDate))"
        }
    }

    // MARK: - Agregação de Sinais Vitais
    static func buildVitalSeries(
        samples: [HourlyVitalSample],
        timeframe: HealthTimeframe,
        anchorDate: Date
    ) -> [VitalChartPoint] {
        let calendar = Calendar.current
        let startOfAnchor = calendar.startOfDay(for: anchorDate)

        switch timeframe {
        case .day:
            let targetKey = dateKey(for: startOfAnchor)
            let daySamples = samples
                .filter { $0.dateKey == targetKey && ($0.heartRate > 0 || $0.spo2 > 0 || $0.systolicBP > 0) }
                .sorted { $0.hour < $1.hour }

            return daySamples.map { s in
                VitalChartPoint(
                    id: s.sampleID,
                    label: String(format: "%02dh", s.hour),
                    date: s.timestamp,
                    avgHeartRate: Double(s.heartRate),
                    minHeartRate: s.heartRate,
                    maxHeartRate: s.heartRate,
                    avgSpO2: Double(s.spo2),
                    minSpO2: s.spo2,
                    avgSystolic: Double(s.systolicBP),
                    avgDiastolic: Double(s.diastolicBP),
                    sampleCount: 1
                )
            }

        case .week, .month:
            let daysCount = timeframe == .week ? 7 : 30
            var points: [VitalChartPoint] = []

            for offset in stride(from: -(daysCount - 1), through: 0, by: 1) {
                guard let dayDate = calendar.date(byAdding: .day, value: offset, to: startOfAnchor) else { continue }
                let key = dateKey(for: dayDate)
                let matching = samples.filter { $0.dateKey == key }

                let hrs = matching.map(\.heartRate).filter { $0 > 0 }
                let spo2s = matching.map(\.spo2).filter { $0 > 0 }
                let sbps = matching.map(\.systolicBP).filter { $0 > 0 }
                let dbps = matching.map(\.diastolicBP).filter { $0 > 0 }

                if !hrs.isEmpty || !spo2s.isEmpty || !sbps.isEmpty {
                    let avgHR = hrs.isEmpty ? 0 : Double(hrs.reduce(0, +)) / Double(hrs.count)
                    let avgSp = spo2s.isEmpty ? 0 : Double(spo2s.reduce(0, +)) / Double(spo2s.count)
                    let avgS = sbps.isEmpty ? 0 : Double(sbps.reduce(0, +)) / Double(sbps.count)
                    let avgD = dbps.isEmpty ? 0 : Double(dbps.reduce(0, +)) / Double(dbps.count)

                    points.append(
                        VitalChartPoint(
                            id: key,
                            label: shortDayLabel(for: dayDate),
                            date: dayDate,
                            avgHeartRate: avgHR,
                            minHeartRate: hrs.min() ?? 0,
                            maxHeartRate: hrs.max() ?? 0,
                            avgSpO2: avgSp,
                            minSpO2: spo2s.min() ?? 0,
                            avgSystolic: avgS,
                            avgDiastolic: avgD,
                            sampleCount: matching.count
                        )
                    )
                }
            }
            return points
        }
    }

    // MARK: - Agregação de Atividades
    static func buildActivitySeries(
        dailyRecords: [DailyActivityRecord],
        hourlySamples: [HourlyVitalSample],
        timeframe: HealthTimeframe,
        anchorDate: Date
    ) -> [ActivityChartPoint] {
        let calendar = Calendar.current
        let startOfAnchor = calendar.startOfDay(for: anchorDate)

        switch timeframe {
        case .day:
            let targetKey = dateKey(for: startOfAnchor)
            let sorted = hourlySamples
                .filter { $0.dateKey == targetKey }
                .sorted { $0.hour < $1.hour }

            var points: [ActivityChartPoint] = []
            for (idx, sample) in sorted.enumerated() {
                let prevSteps = idx > 0 ? sorted[idx - 1].cumulativeSteps : 0
                let prevKcal = idx > 0 ? sorted[idx - 1].cumulativeCalories : 0
                let deltaSteps = max(0, sample.cumulativeSteps - prevSteps)
                let deltaKcal = max(0, sample.cumulativeCalories - prevKcal)

                if deltaSteps > 0 || sample.cumulativeSteps > 0 {
                    points.append(
                        ActivityChartPoint(
                            id: sample.sampleID,
                            label: String(format: "%02dh", sample.hour),
                            date: sample.timestamp,
                            steps: deltaSteps,
                            calories: deltaKcal,
                            distanceKm: (Double(deltaSteps) * 0.74) / 1000.0
                        )
                    )
                }
            }
            return points

        case .week, .month:
            let daysCount = timeframe == .week ? 7 : 30
            let byKey = Dictionary(uniqueKeysWithValues: dailyRecords.map { ($0.dateKey, $0) })
            var points: [ActivityChartPoint] = []

            for offset in stride(from: -(daysCount - 1), through: 0, by: 1) {
                guard let dayDate = calendar.date(byAdding: .day, value: offset, to: startOfAnchor) else { continue }
                let key = dateKey(for: dayDate)
                let rec = byKey[key]
                points.append(
                    ActivityChartPoint(
                        id: key,
                        label: shortDayLabel(for: dayDate),
                        date: dayDate,
                        steps: rec?.steps ?? 0,
                        calories: rec?.calories ?? 0,
                        distanceKm: rec?.estimatedDistanceKm ?? 0
                    )
                )
            }
            return points
        }
    }

    // MARK: - Agregação de Sono
    static func buildSleepSeries(
        dailyRecords: [DailyActivityRecord],
        timeframe: HealthTimeframe,
        anchorDate: Date
    ) -> [SleepChartPoint] {
        let calendar = Calendar.current
        let startOfAnchor = calendar.startOfDay(for: anchorDate)
        let daysCount = timeframe == .day ? 1 : (timeframe == .week ? 7 : 30)
        let byKey = Dictionary(uniqueKeysWithValues: dailyRecords.map { ($0.dateKey, $0) })

        var points: [SleepChartPoint] = []
        for offset in stride(from: -(daysCount - 1), through: 0, by: 1) {
            guard let dayDate = calendar.date(byAdding: .day, value: offset, to: startOfAnchor) else { continue }
            let key = dateKey(for: dayDate)
            if let rec = byKey[key], rec.totalSleepMinutes > 0 {
                points.append(
                    SleepChartPoint(
                        id: key,
                        label: shortDayLabel(for: dayDate),
                        date: dayDate,
                        deepMinutes: rec.deepSleepMinutes,
                        lightMinutes: rec.lightSleepMinutes
                    )
                )
            }
        }
        return points
    }
}