import SwiftUI

struct ConnectionStatusHeader: View {
    @ObservedObject var bleManager: BLEManager
    @ObservedObject var syncEngine: BMLSyncEngine
    @ObservedObject var settingsStore: DeviceSettingsStore
    @State private var showingScannerSheet = false

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(bleManager.isConnected ? BMLTheme.accentVitality : Color.secondary.opacity(0.4))
                .frame(width: 10, height: 10)
                .shadow(color: bleManager.isConnected ? BMLTheme.accentVitality.opacity(0.6) : .clear, radius: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(bleManager.isConnected ? bleManager.connectedDeviceName : "BML X Pro Max 5")
                    .font(BMLTypography.sectionTitle)
                    .foregroundStyle(.primary)

                Text(statusSubtitle)
                    .font(BMLTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let battery = settingsStore.lastBatteryLevel {
                HStack(spacing: 4) {
                    Image(systemName: settingsStore.lastIsCharging ? "bolt.fill" : "battery.75")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(battery <= 20 ? BMLTheme.accentHeart : BMLTheme.accentVitality)
                    Text("\(battery)%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(BMLTheme.surfaceElevated, in: Capsule())
            }

            if bleManager.isConnected {
                Button(action: { bleManager.sendSyncData() }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                        .rotationEffect(.degrees(syncEngine.isSyncing ? 360 : 0))
                        .animation(syncEngine.isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: syncEngine.isSyncing)
                        .padding(8)
                        .background(BMLTheme.accentVitality.opacity(0.15), in: Circle())
                        .foregroundStyle(BMLTheme.accentVitality)
                }
                .accessibilityLabel("Sincronizar agora")
            } else {
                Button(action: { showingScannerSheet = true }) {
                    Text("Conectar")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(BMLTheme.accentVitality, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
        .bmlCard(padding: 14)
        .sheet(isPresented: $showingScannerSheet) {
            WatchConnectionSheet(bleManager: bleManager)
                .presentationDetents([.medium])
        }
    }

    private var statusSubtitle: String {
        if bleManager.isConnected {
            if let lastSync = settingsStore.lastSyncDate {
                return "Conectado • Sync \(lastSync.formatted(date: .omitted, time: .shortened))"
            }
            return "Conectado via CoreBluetooth"
        }
        return bleManager.bluetoothStateText
    }
}

struct WatchConnectionSheet: View {
    @ObservedObject var bleManager: BLEManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    Button(action: {
                        bleManager.isScanning ? bleManager.stopScan() : bleManager.startScan()
                    }) {
                        Label(
                            bleManager.isScanning ? "Parar Busca" : "Buscar Relógio",
                            systemImage: "antenna.radiowaves.left.and.right"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BMLTheme.accentVitality)

                    if bleManager.hasSavedWatch {
                        Button("Reconectar") {
                            bleManager.attemptAutoReconnect()
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if bleManager.discoveredDevices.isEmpty {
                    ContentUnavailableView(
                        "Procurando BML X Pro Max 5",
                        systemImage: "applewatch.radiowaves.left.and.right",
                        description: Text("Certifique-se de que o relógio está desconectado do Wearfit Pro e próximo ao iPhone 11.")
                    )
                } else {
                    List(bleManager.discoveredDevices) { watch in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(watch.name)
                                    .font(BMLTypography.sectionTitle)
                                Text("MAC: \(watch.macHex ?? "Oculto") • Sinal: \(watch.rssi) dBm")
                                    .font(BMLTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Conectar") {
                                bleManager.connect(to: watch)
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(BMLTheme.accentVitality)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .padding()
            .navigationTitle("Parear Relógio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") {
                        bleManager.stopScan()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if !bleManager.isScanning {
                    bleManager.startScan()
                }
            }
        }
    }
}