import SwiftUI

struct BLEProofOfConceptView: View {
    @ObservedObject var bleManager: BLEManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                // Status Card
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bleManager.isConnected ? bleManager.connectedDeviceName : "BML X Pro Max 5")
                            .font(.headline)
                        Text(bleManager.isConnected ? "Conectado via CoreBluetooth" : bleManager.bluetoothStateText)
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

                if !bleManager.isConnected {
                    // Controles de Busca
                    Button(action: {
                        bleManager.isScanning ? bleManager.stopScan() : bleManager.startScan()
                    }) {
                        Label(bleManager.isScanning ? "Parar Busca" : "Buscar BML X Pro Max 5", systemImage: "antenna.radiowaves.left.and.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if !bleManager.discoveredDevices.isEmpty {
                        List(bleManager.discoveredDevices) { watch in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(watch.name).font(.headline)
                                    Text("MAC: \(watch.macHex ?? "Oculto") • Sinal: \(watch.rssi) dBm")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Conectar") {
                                    bleManager.connect(to: watch)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .frame(maxHeight: 160)
                        .listStyle(.plain)
                    }
                } else {
                    // Métricas Decodificadas em Tempo Real
                    HStack(spacing: 10) {
                        metricBadge(title: "Passos", value: bleManager.telemetry.steps.map(String.init) ?? "--")
                        metricBadge(title: "Calorias", value: bleManager.telemetry.calories.map { "\($0) kcal" } ?? "--")
                        metricBadge(title: "FC", value: bleManager.telemetry.heartRate.map { "\($0) bpm" } ?? "--")
                        metricBadge(title: "SpO2", value: bleManager.telemetry.spo2.map { "\($0)%" } ?? "--")
                    }

                    // Comandos Validados na Fase 2
                    HStack(spacing: 8) {
                        Button("Sincronizar Hora") { bleManager.sendSyncTime() }
                            .buttonStyle(.bordered)
                        Button("Sincronizar Dados") { bleManager.sendSyncData() }
                            .buttonStyle(.borderedProminent)
                        Button("Vibrar") { bleManager.sendFindWatch(activate: true) }
                            .buttonStyle(.bordered)
                    }
                    .font(.caption.bold())

                    Button("Desconectar", role: .destructive) {
                        bleManager.disconnect()
                    }
                    .font(.caption)
                }

                // Console Técnico In-App
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Console BLE (Prova de Conceito — Fase 3)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Limpar") { bleManager.clearLogs() }
                            .font(.caption)
                    }

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(bleManager.logs) { entry in
                                Text("[\(entry.formattedTime)] \(entry.direction.rawValue) \(entry.message)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(entry.direction == .error ? .red : (entry.direction == .tx ? .blue : .primary))
                            }
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .navigationTitle("BML Control (POC)")
        }
    }

    private func metricBadge(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}