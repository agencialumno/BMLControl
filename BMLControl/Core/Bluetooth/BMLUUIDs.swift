import CoreBluetooth

enum BMLUUIDs {
    // Serviço Primário de Comandos (Nordic UART Service 1)
    static let primaryService = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    static let primaryWriteRX = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    static let primaryNotifyTX = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")

    // Serviço Secundário de Transferência em Lote (Nordic UART Service 2)
    static let secondaryService = CBUUID(string: "6E400011-B5A3-F393-E0A9-E50E24DCCA9E")
    static let secondaryWriteRX = CBUUID(string: "6E400012-B5A3-F393-E0A9-E50E24DCCA9E")
    static let secondaryNotifyTX = CBUUID(string: "6E400013-B5A3-F393-E0A9-E50E24DCCA9E")

    // Assinatura física do BML X Pro Max 5 no Manufacturer Data (0xFFF0)
    static let expectedDeviceName = "X5 Pro Max"
    static let expectedMacBytes: [UInt8] = [0x41, 0x42, 0x75, 0xA4, 0x3F, 0xA2]
}