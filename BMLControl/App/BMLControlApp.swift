import SwiftUI
import SwiftData

@main
struct BMLControlApp: App {
    let modelContainer: ModelContainer
    @StateObject private var bleManager: BLEManager
    @StateObject private var settingsStore: DeviceSettingsStore
    @StateObject private var syncEngine: BMLSyncEngine

    init() {
        do {
            let schema = Schema([
                DailyActivityRecord.self,
                HourlyVitalSample.self,
                SleepSegmentRecord.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [config])
            self.modelContainer = container

            let ble = BLEManager()
            let settings = DeviceSettingsStore()
            let sync = BMLSyncEngine(modelContext: container.mainContext, settingsStore: settings)

            ble.onDecodedEvent = { event in
                sync.handleDecodedEvent(event)
            }
            ble.onSyncStarted = {
                sync.isSyncing = true
            }

            _bleManager = StateObject(wrappedValue: ble)
            _settingsStore = StateObject(wrappedValue: settings)
            _syncEngine = StateObject(wrappedValue: sync)
        } catch {
            fatalError("Falha crítica ao inicializar SwiftData: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            BLEProofOfConceptView(
                bleManager: bleManager,
                syncEngine: syncEngine,
                settingsStore: settingsStore
            )
            .modelContainer(modelContainer)
        }
    }
}