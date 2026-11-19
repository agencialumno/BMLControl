import XCTest
import SwiftData
@testable import BMLControl

@MainActor
final class BMLSyncEngineTests: XCTestCase {
    func testUpsertPreventsDuplicateRecordsOnMultipleSyncs() throws {
        let schema = Schema([
            DailyActivityRecord.self,
            HourlyVitalSample.self,
            SleepSegmentRecord.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let settings = DeviceSettingsStore()
        let syncEngine = BMLSyncEngine(modelContext: container.mainContext, settingsStore: settings)

        let event = BMLDecodedEvent.hourlyVital(
            sampleID: "2026-11-19-12",
            dateKey: "2026-11-19",
            timestamp: Date(),
            hour: 12,
            steps: 2678,
            calories: 145,
            heartRate: 76,
            spo2: 99,
            systolicBP: 128,
            diastolicBP: 78
        )

        // Simula duas sincronizações consecutivas do mesmo horário
        syncEngine.handleDecodedEvent(event)
        syncEngine.handleDecodedEvent(event)

        XCTAssertEqual(syncEngine.totalPersistedDays, 1)
        XCTAssertEqual(syncEngine.totalPersistedHourlySamples, 1)
    }
}