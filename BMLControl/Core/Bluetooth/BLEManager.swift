import Foundation
import CoreBluetooth

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
    @Published var telemetry = BMLTelemetrySnapshot()
    @Published var logs: [BLELogEntry] = []

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var primaryWriteCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func startScan() {
        guard centralManager.state == .poweredOn else {
            log(.error, "Bluetooth não está ligado no iPhone.")
            return
        }
        discoveredDevices.removeAll()
        isScanning = true
        log(.info, "Iniciando busca BLE pelo X5 Pro Max...")
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScan() {
        centralManager.stopScan()
        isScanning = false
        log(.info, "Busca BLE encerrada.")
    }

    func connect(to watch: DiscoveredWatch) {
        stopScan()
        log(.info, "Conectando a \(watch.name) (\(watch.macHex ?? watch.id.uuidString))...")
        connectedPeripheral = watch.peripheral
        watch.peripheral.delegate = self
        centralManager.connect(watch.peripheral, options: nil)
    }

    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }

    func sendSyncTime() {
        let packet = BMLPacketParser.buildSyncTimeCommand()
        sendCommand(packet, label: "Sincronizar Data/Hora (0x93)")
    }

    func sendSyncData() {
        let packet = BMLPacketParser.buildSyncTodayDataCommand()
        sendCommand(packet, label: "Sincronizar Passos/Vitais/Sono (0x51)")
    }

    func sendFindWatch(activate: Bool = true) {
        let packet = BMLPacketParser.buildFindWatchCommand(activate: activate)
        sendCommand(packet, label: activate ? "Encontrar Relógio ON (0x71)" : "Encontrar Relógio OFF (0x71)")
    }

    func clearLogs() {
        logs.removeAll()
    }

    private func sendCommand(_ data: Data, label: String) {
        guard let peripheral = connectedPeripheral, let char = primaryWriteCharacteristic else {
            log(.error, "Canal 6E400002 indisponível. Conecte o relógio primeiro.")
            return
        }
        let hex = data.map { String(format: "%02X", $0) }.joined(separator: " ")
        log(.tx, "[\(label)] \(hex)")
        peripheral.writeValue(data, for: char, type: .withoutResponse)
    }

    private func log(_ direction: BLELogEntry.Direction, _ message: String) {
        logs.insert(BLELogEntry(timestamp: Date(), direction: direction, message: message), at: 0)
        if logs.count > 250 {
            logs.removeLast()
        }
    }
}

extension BLEManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                bluetoothStateText = "Bluetooth Ativo"
                log(.info, "Rádio Bluetooth pronto.")
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
            let name = advName ?? peripheral.name ?? "Dispositivo Sem Nome"

            var extractedMac: String?
            if let mfgData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data, mfgData.count >= 8 {
                // Os 2 primeiros bytes no CoreBluetooth são o Company ID (0xFFF0), seguidos pelos 6 bytes do MAC
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
            log(.error, "Desconectado do relógio. \(error?.localizedDescription ?? "")")
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
                    log(.info, "Canal TX pronto (6E400002).")
                } else if char.uuid == BMLUUIDs.primaryNotifyTX || char.uuid == BMLUUIDs.secondaryNotifyTX {
                    peripheral.setNotifyValue(true, for: char)
                    log(.info, "Escuta Notify ativada em \(char.uuid.uuidString.prefix(8)).")
                }
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Task { @MainActor in
            guard let data = characteristic.value else { return }
            let hex = data.map { String(format: "%02X", $0) }.joined(separator: " ")
            if let decoded = BMLPacketParser.parse(data, into: &telemetry) {
                log(.rx, "\(decoded) | Raw: \(hex)")
            } else {
                log(.rx, "Raw: \(hex)")
            }
        }
    }
}