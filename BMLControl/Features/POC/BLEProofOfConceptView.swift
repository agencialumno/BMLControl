import SwiftUI

struct BLEProofOfConceptView: View {
    @ObservedObject var bleManager: BLEManager
    @State private var raiseWristEnabled = true
    @State private var is24HourFormat = true
    @State private var dndEnabled = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    connectionHeaderCard

                    if !bleManager.isConnected {
                        scanSection
                    } else {
                        metricsGridSection
                        confirmedWriteControlsSection
                        experimentalWriteControlsSection
                        hourlyHistorySection
                    }

                    consoleSection
                }
                .padding()
            }
            .navigationTitle("BML Control • Fase 4")
        }
    }

    private var connectionHeaderCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bleManager.isConnected ? bleManager.connectedDeviceName : "BML X Pro Max 5")
                    .font(.headline)
                Text(bleManager.isConnected ? "Sincronização bidirecional ativa" : bleManager.bluetoothStateText)
                    .font(.caption)
                    .foregroundStyle(bleManager.isConnected ? .green : .secondary)
            }
            Spacer()
            if let battery = bleManager.telemetry.batteryLevel {
                Label("\(battery)%", systemImage: bleManager.telemetry.isCharging == true ? "battery.100.bolt" : "battery.75")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
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

    private var metricsGridSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                metricCard(title: "Passos", value: bleManager.telemetry.steps.map(String.init) ?? "--")
                metricCard(title: "Calorias", value: bleManager.telemetry.calories.map { "\($0) kcal" } ?? "--")
                metricCard(title: "Sono Total", value: bleManager.telemetry.totalSleepFormatted)
            }
            HStack(spacing: 8) {
                metricCard(title: "Batimentos", value: bleManager.telemetry.heartRate.map { "\($0) bpm" } ?? "--")
                metricCard(title: "SpO2", value: bleManager.telemetry.spo2.map { "\($0)%" } ?? "--")
                metricCard(
                    title: "Pressão (Est.)",
                    value: {
                        if let sbp = bleManager.telemetry.systolicBP, let dbp = bleManager.telemetry.diastolicBP {
                            return "\(sbp)/\(dbp)"
                        }
                        return "--"
                    }()
                )
            }
        }
    }

    private var confirmedWriteControlsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Comandos Confirmados")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button("Hora (0x93)") { bleManager.sendSyncTime() }
                    .buttonStyle(.bordered)
                Button("Dados (0x51)") { bleManager.sendSyncData() }
                    .buttonStyle(.borderedProminent)
                Button("Vibrar (0x71)") { bleManager.sendFindWatch(activate: true) }
                    .buttonStyle(.bordered)
            }
            .font(.caption.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var experimentalWriteControlsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Validação de Escrita (Testar no Relógio)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                if let ack = bleManager.telemetry.lastAckHex {
                    Text("Último ACK: \(ack)")
                        .font(.caption2.bold())
                        .foregroundStyle(.green)
                }
            }

            Toggle("Levantar Pulso (0x77)", isOn: $raiseWristEnabled)
                .font(.subheadline)
                .onChange(of: raiseWristEnabled) { _, newValue in
                    bleManager.sendRaiseWrist(enabled: newValue)
                }

            Toggle("Formato 24 Horas (0x7C)", isOn: $is24HourFormat)
                .font(.subheadline)
                .onChange(of: is24HourFormat) { _, newValue in
                    bleManager.sendTimeFormat(is24Hour: newValue)
                }

            Toggle("Modo Não Perturbe (0x76)", isOn: $dndEnabled)
                .font(.subheadline)
                .onChange(of: dndEnabled) { _, newValue in
                    bleManager.sendDoNotDisturb(enabled: newValue)
                }

            HStack {
                Button("Definir Meta 8.000 Passos (0x74)") {
                    bleManager.sendStepGoal(8000)
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

    private var hourlyHistorySection: some View {
        Group {
            if !bleManager.telemetry.hourlyRecords.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Leituras Horárias Decodificadas (\(bleManager.telemetry.hourlyRecords.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ForEach(bleManager.telemetry.hourlyRecords.prefix(5)) { item in
                        HStack {
                            Text(item.timestampLabel).font(.caption.bold())
                            Spacer()
                            Text("\(item.steps)p • \(item.heartRate)bpm • \(item.spo2)%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var consoleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Console BLE em Tempo Real")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Limpar") { bleManager.clearLogs() }
                    .font(.caption)
            }

            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(bleManager.logs.prefix(40)) { entry in
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