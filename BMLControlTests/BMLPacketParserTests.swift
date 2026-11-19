import XCTest
@testable import BMLControl

final class BMLPacketParserTests: XCTestCase {
    func testDecodeBatteryPacket() {
        let rawBytes: [UInt8] = [0xAB, 0x00, 0x05, 0xFF, 0x91, 0x80, 0x00, 0x42]
        let output = BMLPacketParser.decode(Data(rawBytes))

        XCTAssertEqual(output?.event, .battery(level: 66, isCharging: false))
    }

    func testDecodeHourlyVitalsPacket() {
        let rawBytes: [UInt8] = [
            0xAB, 0x00, 0x19, 0xFF, 0x51, 0x20,
            0x1A, 0x0B, 0x13, 0x0C,
            0x00, 0x0A, 0x76,
            0x00, 0x00, 0x91,
            0x4C, 0x63, 0x80, 0x4E,
            0x01, 0x1E, 0x09, 0x0A, 0x02, 0x00, 0x03, 0x05
        ]
        let output = BMLPacketParser.decode(Data(rawBytes))

        guard case .hourlyVital(let sampleID, let dateKey, _, let hour, let steps, let calories, let hr, let spo2, let sbp, let dbp) = output?.event else {
            return XCTFail("Evento esperado: hourlyVital")
        }

        XCTAssertEqual(sampleID, "2026-11-19-12")
        XCTAssertEqual(dateKey, "2026-11-19")
        XCTAssertEqual(hour, 12)
        XCTAssertEqual(steps, 2678)
        XCTAssertEqual(calories, 145)
        XCTAssertEqual(hr, 76)
        XCTAssertEqual(spo2, 99)
        XCTAssertEqual(sbp, 128)
        XCTAssertEqual(dbp, 78)
    }

    func testCommandBuilderValidatedAndSmartCommands() {
        XCTAssertEqual([UInt8](BMLCommandBuilder.setStepGoal(8000)), [0xAB, 0x00, 0x07, 0xFF, 0x74, 0x80, 0x00, 0x00, 0x1F, 0x40])
        XCTAssertEqual([UInt8](BMLCommandBuilder.setRaiseWristToWake(enabled: true)), [0xAB, 0x00, 0x04, 0xFF, 0x77, 0x80, 0x01])
        XCTAssertEqual([UInt8](BMLCommandBuilder.set24HourFormat(is24Hour: false)), [0xAB, 0x00, 0x04, 0xFF, 0x7C, 0x80, 0x01])

        // Comandos da Fase 8
        XCTAssertEqual([UInt8](BMLCommandBuilder.setAlarm(index: 0, enabled: true, hour: 7, minute: 30, repeatMask: 0x7F)), [0xAB, 0x00, 0x08, 0xFF, 0x73, 0x80, 0x00, 0x01, 0x07, 0x1E, 0x7F])
        XCTAssertEqual([UInt8](BMLCommandBuilder.syncWeather(conditionCode: 0x01, currentTemp: 28, minTemp: 21, maxTemp: 31)), [0xAB, 0x00, 0x08, 0xFF, 0x7E, 0x80, 0x01, 0x1C, 0x1F, 0x15, 0x00])
        XCTAssertEqual([UInt8](BMLCommandBuilder.setRemoteCameraMode(enabled: true)), [0xAB, 0x00, 0x04, 0xFF, 0x79, 0x80, 0x01])
    }
}