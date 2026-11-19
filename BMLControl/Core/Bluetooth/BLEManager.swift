import Foundation
import CoreBluetooth
import AudioToolbox

struct DiscoveredWatch: Identifiable {
    let id: UUID
    let peripheral: CBPeripheral
    let name: String
    let rssi: Int
    let macHex: String?
}

@MainActor
final class BLEManager: NSObject, ObservableObject {
    @Published var bluetoothStateText: String = "Inicializando Bluetooth..."
    @Published var isScanning: Bool = false
    @Published var isConnected: Bool = false
    @Published var connectedDeviceName: String = "Desconectado"
    @Published var discoveredDevices: [DiscoveredWatch] = []
    @Published var logs: [BLELogEntry] = []
    @Published var hasSavedWatch: Bool = false
    @Published var lastRemoteCameraTrigger: Date?
    @Published var isFindingPhoneAlertActive: Bool = false

    var onDecodedEvent: ((BMLDecodedEvent) -> Void)?
    var onSyncStarted: (() -> Void)?

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var primaryWriteCharacteristic: CBCharacteristic?
    private let savedPeripheralKey = "bml_saved_watch_uuid"

    override init() {
        super.init()
        hasSavedWatch = UserDefaults.standard.string(forKey: savedPeripheralKey) != nil
        centralManager = CBCentralManager(
            delegate: self,
            queue: .main,
            options: [CBCentralManagerOptionRestoreIdentifierKey: "com.victor.bmlcontrol.central"]
        )
    }

    func startScan() {
        guard centralManager.state == .poweredOn else {
            log(.error, "Bluetooth não está ligado no iPhone.")
            return
        }
        discoveredDevices.removeAll()
        isScanning = true
        log(.info, "Buscando BML X Pro Max 5...")
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScan() {
        centralManager.stopScan()
        isScanning = false
    }

    func connect(to watch: DiscoveredWatch) {
        stopScan()
        UserDefaults.standard.set(watch.id.uuidString, forKey: savedPeripheralKey)
        hasSavedWatch = true
        connectPeripheral(watch.peripheral, displayName: watch.name)
    }

    func attemptAutoReconnect() {
        guard centralManager.state == .poweredOn,
              !isConnected,
              let uuidString = UserDefaults.standard.string(forKey: savedPeripheralKey),
              let uuid = UUID(uuidString: uuidString) else {
            return
        }

        let knownPeripherals = centralManager.retrievePeripherals(withIdentifiers: [uuid])
        if let peripheral = knownPeripherals.first {
            log(.info, "Reconectando automaticamente ao relógio salvo...")
            connectPeripheral(peripheral, displayName: peripheral.name ?? BMLUUIDs.expectedDeviceName)
        }
    }

    func forgetSavedWatch() {
        disconnect()
        UserDefaults.standard.removeObject(forKey: savedPeripheralKey)
        hasSavedWatch = false
        log(.info, "Vínculo salvo do relógio removido.")
    }

    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }

    // MARK: - Comandos Validados e Funções Inteligentes (TX)

    func sendSyncTime() {
        sendCommand(BMLCommandBuilder.syncTime(), label: "Sincronizar Hora (0x93)")
    }

    func sendSyncData() {
        onSyncStarted?()
        sendCommand(BMLCommandBuilder.syncData(), label: "Sincronizar Histórico (0x51)")
    }

    func sendFindWatch(activate: Bool = true) {
        sendCommand(BMLCommandBuilder.findWatch(activate: activate), label: activate ? "Vibrar ON (0x71)" : "Vibrar OFF (0x71)")
    }

    func sendRaiseWrist(enabled: Bool) {
        sendCommand(BMLCommandBuilder.setRaiseWristToWake(enabled: enabled), label: "Levantar Pulso \(enabled ? "ON" : "OFF") (0x77)")
    }

    func sendTimeFormat(is24Hour: Bool) {
        sendCommand(BMLCommandBuilder.set24HourFormat(is24Hour: is24Hour), label: "Formato \(is24Hour ? "24h" : "12h") (0x7C)")
    }

    func sendStepGoal(_ steps: Int) {
        sendCommand(BMLCommandBuilder.setStepGoal(steps), label: "Meta \(steps) passos (0x74)")
    }

    func sendNotificationMask(_ mask: UInt16) {
        sendCommand(BMLCommandBuilder.setNotificationMask(mask), label: String(format: "Alertas ANCS 0x%04X (0x72)", mask))
    }

    func sendAlarm(_ alarm: WatchAlarmItem) {
        let packet = BMLCommandBuilder.setAlarm(
            index: alarm.id,
            enabled: alarm.isEnabled,
            hour: alarm.hour,
            minute: alarm.minute,
            repeatMask: alarm.repeatMask
        )
        sendCommand(packet, label: "Alarme #\(alarm.id + 1) \(alarm.formattedTime) (0x73)")
    }

    func sendWeather(_ weather: WeatherSnapshot) {
        let packet = BMLCommandBuilder.syncWeather(
            conditionCode: weather.watchConditionCode,
            currentTemp: weather.currentTemp,
            minTemp: weather.minTemp,
            maxTemp: weather.maxTemp
        )
        sendCommand(packet, label: "Clima \(weather.currentTemp)°C (0x7E)")
    }

    func sendRemoteCamera(enabled: Bool) {
        sendCommand(BMLCommandBuilder.setRemoteCameraMode(enabled: enabled), label: "Câmera Remota \(enabled ? "ON" : "OFF") (0x79)")
    }

    func clearLogs() {
        logs.removeAll()
    }

    private func triggerPhoneAlertFeedback() {
        isFindingPhoneAlertActive = true
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        AudioServicesPlaySystemSound(1005)
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            isFindingPhoneAlertActive = false
        }
    }

    private func connectPeripheral(_ peripheral: CBPeripheral, displayName: String) {
        log(.info, "Conectando a \(displayName)...")
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }

    private func sendCommand(_ data: Data, label: String) {
        guard let peripheral = connectedPeripheral, let char = primaryWriteCharacteristic else {
            log(.error, "Canal 6E400002 indisponível.")
            return
        }
        let hex = data.map { String(format: "%02X", $0) }.joined(separator: " ")
        log(.tx, "[\(label)] \(hex)")
        peripheral.writeValue(data, for: char, type: .withoutResponse)
    }

    private func log(_ direction: BLELogEntry.Direction, _ message: String) {
        logs.insert(BLELogEntry(timestamp: Date(), direction: direction, message: message), at: 0)
        if logs.count > 300 {
            logs.removeLast()
        }
    }
}

extension BLEManager: CBCentralManagerDelegate {
    nonisolated func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        guard let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral],
              let restored = peripherals.first else {
            return
        }
        Task { @MainActor in
            self.connectedPeripheral = restored
            restored.delegate = self
            if restored.state == .connected {
                self.isConnected = true
                self.connectedDeviceName = restored.name ?? BMLUUIDs.expectedDeviceName
                restored.discoverServices([BMLUUIDs.primaryService, BMLUUIDs.secondaryService])
                self.log(.info, "Sessão BLE restaurada em segundo plano.")
            }
        }
    }

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                bluetoothStateText = "Bluetooth Ativo"
                log(.info, "Rádio Bluetooth ativo.")
                attemptAutoReconnect()
            case .poweredOff:
                bluetoothStateText = "Bluetooth Desligado"
            case .unauthorized:
                bluetoothStateText = "Permissão Bluetooth Negada"
            default:
                bluetoothStateText = "Bluetooth Indisponível"
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        Task { @MainActor in
            let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
            let name = advName ?? peripheral.name ?? "Dispositivo"

            var extractedMac: String?
            if let mfgData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data, mfgData.count >= 8 {
                let macBytes = mfgData.suffix(6)
                extractedMac = macBytes.map { String(format: "%02X", $0) }.joined(separator: ":")
            }

            let isTarget = name.localizedCaseInsensitiveContains("X5") ||
                           name.localizedCaseInsensitiveContains("Wearfit") ||
                           extractedMac == "41:42:75:A4:3F:A2"

            guard isTarget else { return }

            if !discoveredDevices.contains(where: { $0.id == peripheral.identifier }) {
                let watch = DiscoveredWatch(
                    id: peripheral.identifier,
                    peripheral: peripheral,
                    name: name,
                    rssi: RSSI.intValue,
                    macHex: extractedMac
                )
                discoveredDevices.append(watch)
                log(.info, "Encontrado: \(name) | RSSI: \(RSSI) dBm | MAC: \(extractedMac ?? "N/A")")
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            isConnected = true
            connectedDeviceName = peripheral.name ?? "X5 Pro Max"
            log(.info, "Conectado a \(connectedDeviceName). Descobrindo serviços...")
            peripheral.discoverServices([BMLUUIDs.primaryService, BMLUUIDs.secondaryService])
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            isConnected = false
            connectedDeviceName = "Desconectado"
            primaryWriteCharacteristic = nil
            log(.error, "Desconectado. \(error?.localizedDescription ?? "")")
        }
    }
}

extension BLEManager: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            guard let services = peripheral.services else { return }
            for service in services {
                if service.uuid == BMLUUIDs.primaryService {
                    peripheral.discoverCharacteristics([BMLUUIDs.primaryWriteRX, BMLUUIDs.primaryNotifyTX], for: service)
                } else if service.uuid == BMLUUIDs.secondaryService {
                    peripheral.discoverCharacteristics([BMLUUIDs.secondaryWriteRX, BMLUUIDs.secondaryNotifyTX], for: service)
                }
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Task { @MainActor in
            guard let chars = service.characteristics else { return }
            for char in chars {
                if char.uuid == BMLUUIDs.primaryWriteRX {
                    primaryWriteCharacteristic = char
                    log(.info, "Canal de escrita pronto (6E400002).")
                } else if char.uuid == BMLUUIDs.primaryNotifyTX || char.uuid == BMLUUIDs.secondaryNotifyTX {
                    peripheral.setNotifyValue(true, for: char)
                }
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        Task { @MainActor in
            guard characteristic.isNotifying, characteristic.uuid == BMLUUIDs.primaryNotifyTX else { return }
            log(.info, "Notify 6E400003 ativo. Iniciando sincronização automática...")
            sendSyncTime()
            try? await Task.sleep(nanoseconds: 400_000_000)
            sendSyncData()
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Task { @MainActor in
            guard let data = characteristic.value else { return }
            let hex = data.map { String(format: "%02X", $0) }.joined(separator: " ")
            if let output = BMLPacketParser.decode(data) {
                log(.rx, "\(output.logDescription) | \(hex)")
                if output.event == .watchTriggeredFindPhone {
                    triggerPhoneAlertFeedback()
                } else if output.event == .watchTriggeredCameraShutter {
                    lastRemoteCameraTrigger = Date()
                }
                onDecodedEvent?(output.event)
            } else {
                log(.rx, "Não mapeado: \(hex)")
            }
        }
    }
}