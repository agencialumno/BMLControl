import Foundation
import CoreBluetooth
import Combine

final class BLEManager: NSObject, ObservableObject {
    // MARK: - UUIDs do BML X Pro Max 5
    static let nordicUARTServiceUUID    = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    static let uartRXCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    static let uartTXCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")

    static let watchFaceServiceUUID     = CBUUID(string: "6E400011-B5A3-F393-E0A9-E50E24DCCA9E")
    static let watchFaceWriteUUID       = CBUUID(string: "6E400012-B5A3-F393-E0A9-E50E24DCCA9E")
    static let watchFaceNotifyUUID      = CBUUID(string: "6E400013-B5A3-F393-E0A9-E50E24DCCA9E")

    // MARK: - Estado Publicado para a Interface (SwiftUI)
    @Published var isScanning: Bool = false
    @Published var isConnected: Bool = false
    @Published var isANCSAuthorized: Bool = false
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var discoveredPeripherals: [CBPeripheral] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var batteryLevel: Int?
    @Published var lastReceivedHex: String = ""
    @Published var statusMessage: String = "Pronto para conectar"

    // MARK: - Propriedades Internas CoreBluetooth
    private var centralManager: CBCentralManager!
    private var uartRXCharacteristic: CBCharacteristic?
    private var uartTXCharacteristic: CBCharacteristic?
    private var watchFaceWriteCharacteristic: CBCharacteristic?
    private var watchFaceNotifyCharacteristic: CBCharacteristic?

    private let savedPeripheralKey = "BML_LastConnectedWatchUUID"

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Busca e Conexão (com captura de conexão ativa do iOS + ANCS)
    func startScanning() {
    guard centralManager.state == .poweredOn else {
        statusMessage = "Ative o Bluetooth do iPhone"
        return
    }

    discoveredPeripherals.removeAll()

    // Consulta todos os serviços anunciados pelo firmware enquanto o iOS segura o ANCS
    let knownServiceUUIDs: [CBUUID] = [
        Self.nordicUARTServiceUUID,
        Self.watchFaceServiceUUID,
        CBUUID(string: "0000FF12-0000-1000-8000-00805F9B34FB"),
        CBUUID(string: "0000FE59-0000-1000-8000-00805F9B34FB")
    ]

    let systemConnected = centralManager.retrieveConnectedPeripherals(withServices: knownServiceUUIDs)
    if let existingWatch = systemConnected.first(where: {
        ($0.name ?? "").localizedCaseInsensitiveContains("X5") ||
        ($0.name ?? "").localizedCaseInsensitiveContains("BML")
    }) ?? systemConnected.first {
        discoveredPeripherals.append(existingWatch)
        statusMessage = "Relógio detectado no sistema. Conectando..."
        connect(to: existingWatch)
        return
    }

    // Fallback: recupera pelo UUID salvo localmente
    if let uuidString = UserDefaults.standard.string(forKey: savedPeripheralKey),
       let uuid = UUID(uuidString: uuidString),
       let knownWatch = centralManager.retrievePeripherals(withIdentifiers: [uuid]).first {
        discoveredPeripherals.append(knownWatch)
        connect(to: knownWatch)
        return
    }

    // Varredura BLE padrão
    isScanning = true
    statusMessage = "Buscando BML X Pro Max 5..."
    centralManager.scanForPeripherals(withServices: nil, options: [
        CBCentralManagerScanOptionAllowDuplicatesKey: false
    ])
}

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        if !isConnected {
            statusMessage = "Busca encerrada"
        }
    }

    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        statusMessage = "Conectando a \(peripheral.name ?? "X5 Pro Max")..."

        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: savedPeripheralKey)

        // Solicita e mantém a permissão nativa de notificações do iOS (ANCS)
        centralManager.connect(peripheral, options: [
            CBConnectPeripheralOptionRequiresANCS: true
        ])
    }

    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }

    // MARK: - Envio de Comandos (NUS 6E400002)
    func sendCommand(_ data: Data) {
        guard let peripheral = connectedPeripheral,
              let rxChar = uartRXCharacteristic else {
            statusMessage = "Relógio não conectado"
            return
        }

        let writeType: CBCharacteristicWriteType = rxChar.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse

        peripheral.writeValue(data, for: rxChar, type: writeType)
    }

    func sendHexCommand(_ hexString: String) {
        guard let data = Data(hexString: hexString) else { return }
        sendCommand(data)
    }

    // MARK: - Envio de Dados de Watch Face (Serviço 6E400011 -> 6E400012)
    func sendWatchFaceData(_ data: Data) {
        guard let peripheral = connectedPeripheral,
              let wfChar = watchFaceWriteCharacteristic else {
            statusMessage = "Canal de Watch Face indisponível"
            return
        }

        let writeType: CBCharacteristicWriteType = wfChar.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse

        peripheral.writeValue(data, for: wfChar, type: writeType)
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state

        switch central.state {
        case .poweredOn:
            statusMessage = "Bluetooth pronto"
            startScanning()
        case .poweredOff:
            isConnected = false
            isScanning = false
            statusMessage = "Bluetooth desligado"
        case .unauthorized:
            statusMessage = "Permissão de Bluetooth negada nos Ajustes"
        case .unsupported:
            statusMessage = "Bluetooth LE não suportado"
        default:
            statusMessage = "Aguardando Bluetooth..."
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? ""
        guard !name.isEmpty else { return }

        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
        }

        // Conecta automaticamente ao localizar o X5 Pro Max
        if name.localizedCaseInsensitiveContains("X5 Pro") || name.localizedCaseInsensitiveContains("BML") {
            connect(to: peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        isANCSAuthorized = peripheral.ancsAuthorized
        statusMessage = "Conectado a \(peripheral.name ?? "X5 Pro Max")"

        peripheral.discoverServices([
            Self.nordicUARTServiceUUID,
            Self.watchFaceServiceUUID
        ])
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        statusMessage = "Falha ao conectar: \(error?.localizedDescription ?? "erro desconhecido")"
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        uartRXCharacteristic = nil
        uartTXCharacteristic = nil
        watchFaceWriteCharacteristic = nil
        watchFaceNotifyCharacteristic = nil
        statusMessage = "Relógio desconectado"
    }

    // Atualiza em tempo real quando o usuário aceita ou revoga o alerta de notificações do iOS
    func centralManager(_ central: CBCentralManager,
                        didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
        isANCSAuthorized = peripheral.ancsAuthorized
        statusMessage = peripheral.ancsAuthorized
            ? "Conectado (Notificações ANCS ativas)"
            : "Conectado (Ative notificações nos Ajustes)"
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else { return }

        for service in services {
            if service.uuid == Self.nordicUARTServiceUUID {
                peripheral.discoverCharacteristics([
                    Self.uartRXCharacteristicUUID,
                    Self.uartTXCharacteristicUUID
                ], for: service)
            } else if service.uuid == Self.watchFaceServiceUUID {
                peripheral.discoverCharacteristics([
                    Self.watchFaceWriteUUID,
                    Self.watchFaceNotifyUUID
                ], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard error == nil, let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            switch characteristic.uuid {
            case Self.uartRXCharacteristicUUID:
                uartRXCharacteristic = characteristic
            case Self.uartTXCharacteristicUUID:
                uartTXCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            case Self.watchFaceWriteUUID:
                watchFaceWriteCharacteristic = characteristic
            case Self.watchFaceNotifyUUID:
                watchFaceNotifyCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            default:
                break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil, let data = characteristic.value, !data.isEmpty else { return }

        let bytes = [UInt8](data)
        let hex = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
        lastReceivedHex = hex

        // Leitura automática de bateria: AB 00 05 FF 91 80 00 [Porcentagem]
        if characteristic.uuid == Self.uartTXCharacteristicUUID,
           bytes.count >= 8,
           bytes[0] == 0xAB,
           bytes[4] == 0x91 {
            batteryLevel = Int(bytes[7])
        }
    }
}

// MARK: - Helper Hexadecimal
extension Data {
    init?(hexString: String) {
        let cleanHex = hexString.replacingOccurrences(of: " ", with: "")
        guard cleanHex.count % 2 == 0 else { return nil }

        var data = Data(capacity: cleanHex.count / 2)
        var index = cleanHex.startIndex

        while index < cleanHex.endIndex {
            let nextIndex = cleanHex.index(index, offsetBy: 2)
            let byteString = cleanHex[index..<nextIndex]
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        self = data
    }
}