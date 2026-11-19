import XCTest
@testable import BMLControl

final class BMLPacketParserTests: XCTestCase {
    func testParseBatteryPacketFromRealDevice() {
        // Pacote real capturado às 12:55:04 no X5 Pro Max (0x42 = 66%)
        let rawBytes: [UInt8] = [0xAB, 0x00, 0x05, 0xFF, 0x91, 0x80, 0x00, 0x42]
        var snapshot = BMLTelemetrySnapshot()

        let result = BMLPacketParser.parse(Data(rawBytes), into: &snapshot)

        XCTAssertNotNil(result)
        XCTAssertEqual(snapshot.batteryLevel, 66)
        XCTAssertEqual(snapshot.isCharging, false)
    }

    func testParseDailySummaryPacketFromRealDevice() {
        // Pacote real capturado às 13:13:26 no X5 Pro Max (2678 passos, 145 kcal)
        let rawBytes: [UInt8] = [
            0xAB, 0x00, 0x11, 0xFF, 0x51, 0x08,
            0x00, 0x0A, 0x76,
            0x00, 0x00, 0x91,
            0x01, 0x1E, 0x09, 0x0A, 0x02, 0x00, 0x03, 0x05
        ]
        var snapshot = BMLTelemetrySnapshot()

        let result = BMLPacketParser.parse(Data(rawBytes), into: &snapshot)

        XCTAssertNotNil(result)
        XCTAssertEqual(snapshot.steps, 2678)
        XCTAssertEqual(snapshot.calories, 145)
    }

    func testParseHourlyVitalsPacketFromRealDevice() {
        // Pacote real capturado às 13:13:57 no X5 Pro Max (FC 76, SpO2 99, PA 128/78)
        let rawBytes: [UInt8] = [
            0xAB, 0x00, 0x19, 0xFF, 0x51, 0x20,
            0x1A, 0x0B, 0x13, 0x0C,
            0x00, 0x0A, 0x76,
            0x00, 0x00, 0x91,
            0x4C, 0x63, 0x80, 0x4E,
            0x01, 0x1E, 0x09, 0x0A, 0x02, 0x00, 0x03, 0x05
        ]
        var snapshot = BMLTelemetrySnapshot()

        let result = BMLPacketParser.parse(Data(rawBytes), into: &snapshot)

        XCTAssertNotNil(result)
        XCTAssertEqual(snapshot.heartRate, 76)
        XCTAssertEqual(snapshot.spo2, 99)
        XCTAssertEqual(snapshot.systolicBP, 128)
        XCTAssertEqual(snapshot.diastolicBP, 78)
    }
}