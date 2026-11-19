import Foundation
import SwiftData

@MainActor
final class BMLSyncEngine: ObservableObject {
    @Published var isSyncing: Bool = false
    @Published var lastAckHex: String?
    @Published var totalPersistedDays: Int = 0
    @Published var totalPersistedHourlySamples: Int = 0
    @Published var totalPersistedSleepSegments: Int = 0

    private let modelContext: ModelContext
    private let settingsStore: DeviceSettingsStore

    init(modelContext: ModelContext, settingsStore: DeviceSettingsStore) {
        self.modelContext = modelContext
        self.settingsStore = settingsStore
        refreshDatabaseStats()
    }

    func handleDecodedEvent(_ event: BMLDecodedEvent) {
        switch event {
        case .battery(let level, let isCharging):
            settingsStore.lastBatteryLevel = level
            settingsStore.lastIsCharging = isCharging

        case .dailySummary(let dateKey, let steps, let calories, let deepMinutes, let lightMinutes):
            upsertDailyActivity(
                dateKey: dateKey,
                date: Date(),
                steps: steps,
                calories: calories,
                deepMinutes: deepMinutes,
                lightMinutes: lightMinutes
            )
            settingsStore.lastSyncDate = Date()
            isSyncing = false

        case .hourlyVital(let sampleID, let dateKey, let timestamp, let hour, let steps, let calories, let heartRate, let spo2, let sbp, let dbp):
            upsertHourlyVital(
                sampleID: sampleID,
                dateKey: dateKey,
                timestamp: timestamp,
                hour: hour,
                steps: steps,
                calories: calories,
                heartRate: heartRate,
                spo2: spo2,
                systolicBP: sbp,
                diastolicBP: dbp
            )
            upsertDailyActivity(
                dateKey: dateKey,
                date: timestamp,
                steps: steps,
                calories: calories,
                deepMinutes: nil,
                lightMinutes: nil
            )
            settingsStore.lastSyncDate = Date()
            isSyncing = false

        case .hourlyHeartRate(let sampleID, let dateKey, let timestamp, let hour, let bpm):
            guard bpm > 0 else { return }
            upsertHourlyHeartRateOnly(sampleID: sampleID, dateKey: dateKey, timestamp: timestamp, hour: hour, bpm: bpm)

        case .sleepSegment(let segmentID, let dateKey, let startTimestamp, let isDeepSleep, let durationMinutes):
            upsertSleepSegment(
                segmentID: segmentID,
                dateKey: dateKey,
                startTimestamp: startTimestamp,
                isDeepSleep: isDeepSleep,
                durationMinutes: durationMinutes
            )
            recalculateSleepTotals(for: dateKey, fallbackDate: startTimestamp)
            settingsStore.lastSyncDate = Date()

        case .ack(let code):
            lastAckHex = String(format: "0x%02X", code)

        case .heartbeat, .watchTriggeredFindPhone, .watchTriggeredCameraShutter:
            break
        }

        try? modelContext.save()
        refreshDatabaseStats()
    }

    func purgeAllLocalData() {
        do {
            try modelContext.delete(model: DailyActivityRecord.self)
            try modelContext.delete(model: HourlyVitalSample.self)
            try modelContext.delete(model: SleepSegmentRecord.self)
            try modelContext.save()
            refreshDatabaseStats()
        } catch {
            print("Erro ao limpar banco SwiftData: \(error)")
        }
    }

    func refreshDatabaseStats() {
        totalPersistedDays = (try? modelContext.fetchCount(FetchDescriptor<DailyActivityRecord>())) ?? 0
        totalPersistedHourlySamples = (try? modelContext.fetchCount(FetchDescriptor<HourlyVitalSample>())) ?? 0
        totalPersistedSleepSegments = (try? modelContext.fetchCount(FetchDescriptor<SleepSegmentRecord>())) ?? 0
    }

    private func upsertDailyActivity(
        dateKey: String,
        date: Date,
        steps: Int,
        calories: Int,
        deepMinutes: Int?,
        lightMinutes: Int?
    ) {
        let targetKey = dateKey
        var descriptor = FetchDescriptor<DailyActivityRecord>(
            predicate: #Predicate { $0.dateKey == targetKey }
        )
        descriptor.fetchLimit = 1

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.steps = max(existing.steps, steps)
            existing.calories = max(existing.calories, calories)
            existing.stepGoal = settingsStore.dailyStepGoal
            if let deep = deepMinutes, deep > 0, existing.deepSleepMinutes == 0 {
                existing.deepSleepMinutes = deep
            }
            if let light = lightMinutes, light > 0, existing.lightSleepMinutes == 0 {
                existing.lightSleepMinutes = light
            }
            existing.updatedAt = Date()
        } else {
            let record = DailyActivityRecord(
                dateKey: dateKey,
                date: Calendar.current.startOfDay(for: date),
                steps: steps,
                calories: calories,
                stepGoal: settingsStore.dailyStepGoal,
                deepSleepMinutes: deepMinutes ?? 0,
                lightSleepMinutes: lightMinutes ?? 0
            )
            modelContext.insert(record)
        }
    }

    private func upsertHourlyVital(
        sampleID: String,
        dateKey: String,
        timestamp: Date,
        hour: Int,
        steps: Int,
        calories: Int,
        heartRate: Int,
        spo2: Int,
        systolicBP: Int,
        diastolicBP: Int
    ) {
        let targetID = sampleID
        var descriptor = FetchDescriptor<HourlyVitalSample>(
            predicate: #Predicate { $0.sampleID == targetID }
        )
        descriptor.fetchLimit = 1

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.cumulativeSteps = max(existing.cumulativeSteps, steps)
            existing.cumulativeCalories = max(existing.cumulativeCalories, calories)
            if heartRate > 0 { existing.heartRate = heartRate }
            if spo2 > 0 { existing.spo2 = spo2 }
            if systolicBP > 0 { existing.systolicBP = systolicBP }
            if diastolicBP > 0 { existing.diastolicBP = diastolicBP }
        } else {
            let sample = HourlyVitalSample(
                sampleID: sampleID,
                dateKey: dateKey,
                timestamp: timestamp,
                hour: hour,
                cumulativeSteps: steps,
                cumulativeCalories: calories,
                heartRate: heartRate,
                spo2: spo2,
                systolicBP: systolicBP,
                diastolicBP: diastolicBP
            )
            modelContext.insert(sample)
        }
    }

    private func upsertHourlyHeartRateOnly(sampleID: String, dateKey: String, timestamp: Date, hour: Int, bpm: Int) {
        let targetID = sampleID
        var descriptor = FetchDescriptor<HourlyVitalSample>(
            predicate: #Predicate { $0.sampleID == targetID }
        )
        descriptor.fetchLimit = 1

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.heartRate = bpm
        } else {
            let sample = HourlyVitalSample(
                sampleID: sampleID,
                dateKey: dateKey,
                timestamp: timestamp,
                hour: hour,
                heartRate: bpm
            )
            modelContext.insert(sample)
        }
    }

    private func upsertSleepSegment(
        segmentID: String,
        dateKey: String,
        startTimestamp: Date,
        isDeepSleep: Bool,
        durationMinutes: Int
    ) {
        let targetID = segmentID
        var descriptor = FetchDescriptor<SleepSegmentRecord>(
            predicate: #Predicate { $0.segmentID == targetID }
        )
        descriptor.fetchLimit = 1

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.isDeepSleep = isDeepSleep
            existing.durationMinutes = durationMinutes
        } else {
            let segment = SleepSegmentRecord(
                segmentID: segmentID,
                dateKey: dateKey,
                startTimestamp: startTimestamp,
                isDeepSleep: isDeepSleep,
                durationMinutes: durationMinutes
            )
            modelContext.insert(segment)
        }
    }

    private func recalculateSleepTotals(for dateKey: String, fallbackDate: Date) {
        let targetKey = dateKey
        let segDescriptor = FetchDescriptor<SleepSegmentRecord>(
            predicate: #Predicate { $0.dateKey == targetKey }
        )
        guard let segments = try? modelContext.fetch(segDescriptor), !segments.isEmpty else { return }

        let deepTotal = segments.filter { $0.isDeepSleep }.reduce(0) { $0 + $1.durationMinutes }
        let lightTotal = segments.filter { !$0.isDeepSleep }.reduce(0) { $0 + $1.durationMinutes }

        var dayDescriptor = FetchDescriptor<DailyActivityRecord>(
            predicate: #Predicate { $0.dateKey == targetKey }
        )
        dayDescriptor.fetchLimit = 1

        if let existingDay = try? modelContext.fetch(dayDescriptor).first {
            existingDay.deepSleepMinutes = deepTotal
            existingDay.lightSleepMinutes = lightTotal
            existingDay.updatedAt = Date()
        } else {
            let newDay = DailyActivityRecord(
                dateKey: dateKey,
                date: Calendar.current.startOfDay(for: fallbackDate),
                deepSleepMinutes: deepTotal,
                lightSleepMinutes: lightTotal
            )
            modelContext.insert(newDay)
        }
    }
}