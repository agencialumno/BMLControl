import SwiftUI
import SwiftData

struct BLEProofOfConceptView: View {
    @ObservedObject var bleManager: BLEManager
    @ObservedObject var syncEngine: BMLSyncEngine
    @ObservedObject var settingsStore: DeviceSettingsStore

    @Query(sort: \DailyActivityRecord.dateKey, order: .reverse) private var dailyRecords: [DailyActivityRecord]
    @Query(sort: \HourlyVitalSample.sampleID, order: .reverse) private var hourlySamples: [HourlyVitalSample]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    connectionHeaderCard
                    swiftDataStatusCard

                    if !bleManager.isConnected {
                        scanSection
                    } else {
                        confirmedControlsSection
                    }

                    persistedMetricsSection
                    consoleSection
                }
                .padding()
            }
            .navigationTitle("BML Control • Fase 5")
        }
    }

    private var connectionHeaderCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bleManager.isConnected ? bleManager.connectedDeviceName : "BML X Pro Max 5")
                    .font(.headline)
                Text(bleManager.isConnected ? "Conectado • Sync Automático Ativo" : bleManager.bluetoothStateText)
                    .font(.caption)
                    .foregroundStyle(bleManager.isConnected ? .green : .secondary)
            }
            Spacer()
            if let battery = settingsStore.lastBatteryLevel {
                Label("\(battery)%", systemImage: settingsStore.lastIsCharging ? "battery.100.bolt" : "battery.75")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var swiftDataStatusCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Banco Local SwiftData", systemImage: "internaldrive")
                    .font(.caption.bold())
                Spacer()
                if let lastSync = settingsStore.lastSyncDate {
                    Text("Sync: \(lastSync.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text("Salvos offline: \(syncEngine.totalPersistedDays) dias • \(syncEngine.totalPersistedHourlySamples) amostras horárias • \(syncEngine.totalPersistedSleepSegments) blocos de sono")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var scanSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button(action: {
                    bleManager.isScanning ? bleManager.stopScan() : bleManager.startScan()
                }) {
                    Label(bleManager.isScanning ? "Parar Busca" : "Buscar Relógio", systemImage: "antenna.radiowaves.left.and.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if bleManager.hasSavedWatch {
                    Button("Reconectar") {
                        bleManager.attemptAutoReconnect()
                    }
                    .buttonStyle(.bordered)
                }
            }

            ForEach(bleManager.discoveredDevices) { watch in
                HStack {
                    VStack(alignment: .leading) {
                        Text(watch.name).font(.headline)
                        Text("MAC: \(watch.macHex ?? "Oculto") • \(watch.rssi) dBm")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Conectar") {
                        bleManager.connect(to: watch)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var confirmedControlsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Comandos Validados no Hardware")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                if let ack = syncEngine.lastAckHex {
                    Text("ACK: \(ack)")
                        .font(.caption2.bold())
                        .foregroundStyle(.green)
                }
            }

            HStack(spacing: 8) {
                Button("Sincronizar") { bleManager.sendSyncData() }
                    .buttonStyle(.borderedProminent)
                Button("Hora (0x93)") { bleManager.sendSyncTime() }
                    .buttonStyle(.bordered)
                Button("Vibrar (0x71)") { bleManager.sendFindWatch(activate: true) }
                    .buttonStyle(.bordered)
            }
            .font(.caption.bold())

            Toggle("Levantar Pulso (0x77)", isOn: $settingsStore.raiseWristEnabled)
                .font(.subheadline)
                .onChange(of: settingsStore.raiseWristEnabled) { _, newValue in
                    bleManager.sendRaiseWrist(enabled: newValue)
                }

            Toggle("Formato 24 Horas (0x7C)", isOn: $settingsStore.is24HourFormat)
                .font(.subheadline)
                .onChange(of: settingsStore.is24HourFormat) { _, newValue in
                    bleManager.sendTimeFormat(is24Hour: newValue)
                }

            HStack {
                Button("Meta \(settingsStore.dailyStepGoal) Passos (0x74)") {
                    bleManager.sendStepGoal(settingsStore.dailyStepGoal)
                }
                .buttonStyle(.bordered)
                .font(.caption.bold())

                Spacer()

                Button("Desconectar", role: .destructive) {
                    bleManager.disconnect()
                }
                .font(.caption.bold())
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var persistedMetricsSection: some View {
        let latestDay = dailyRecords.first
        let latestSample = hourlySamples.first(where: { $0.heartRate > 0 })

        return VStack(alignment: .leading, spacing: 8) {
            Text("Dados Persistidos (Disponíveis Offline)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                metricCard(title: "Passos", value: latestDay.map { "\($0.steps)" } ?? "--")
                metricCard(title: "Calorias", value: latestDay.map { "\($0.calories) kcal" } ?? "--")
                metricCard(title: "Sono", value: latestDay.map { "\($0.totalSleepMinutes / 60)h \($0.totalSleepMinutes % 60)m" } ?? "--")
            }

            HStack(spacing: 8) {
                metricCard(title: "Batimentos", value: latestSample.map { "\($0.heartRate) bpm" } ?? "--")
                metricCard(title: "SpO2", value: latestSample.map { "\($0.spo2)%" } ?? "--")
                metricCard(title: "Pressão", value: latestSample.map { "\($0.systolicBP)/\($0.diastolicBP)" } ?? "--")
            }
        }
    }

    private var consoleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Console BLE")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Limpar Logs") { bleManager.clearLogs() }
                    .font(.caption)
            }

            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(bleManager.logs.prefix(30)) { entry in
                    Text("[\(entry.formattedTime)] \(entry.direction.rawValue) \(entry.message)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(entry.direction == .error ? .red : (entry.direction == .tx ? .blue : .primary))
                }
            }
        }
        .padding(10)
        .background(Color(.systemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}