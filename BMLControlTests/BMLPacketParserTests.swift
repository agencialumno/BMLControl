import XCTest
@testable import BMLControl

final class BMLPacketParserTests: XCTestCase {
    func testParseBatteryPacketFromRealDevice() {
        let rawBytes: [UInt8] = [0xAB, 0x00, 0x05, 0xFF, 0x91, 0x80, 0x00, 0x42]
        var snapshot = BMLTelemetrySnapshot()

        let result = BMLPacketParser.parse(Data(rawBytes), into: &snapshot)

        XCTAssertNotNil(result)
        XCTAssertEqual(snapshot.batteryLevel, 66)
        XCTAssertEqual(snapshot.isCharging, false)
    }

    func testParseHourlyVitalsAndHistoryArray() {
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
        XCTAssertEqual(snapshot.hourlyRecords.count, 1)
        XCTAssertEqual(snapshot.hourlyRecords.first?.steps, 2678)
    }

    func testParseSleepSegmentsFromRealDevice() {
        // Pacotes reais capturados às 13:13:29 e 13:13:31 no X5 Pro Max
        let lightSleep: [UInt8] = [0xAB, 0x00, 0x0B, 0xFF, 0x52, 0x80, 0x1A, 0x0B, 0x0C, 0x16, 0x20, 0x02, 0x00, 0x17]
        let deepSleep: [UInt8] = [0xAB, 0x00, 0x0B, 0xFF, 0x52, 0x80, 0x1A, 0x0B, 0x0C, 0x15, 0x30, 0x01, 0x00, 0x47]
        var snapshot = BMLTelemetrySnapshot()

        _ = BMLPacketParser.parse(Data(lightSleep), into: &snapshot)
        _ = BMLPacketParser.parse(Data(deepSleep), into: &snapshot)

        XCTAssertEqual(snapshot.lightSleepMinutes, 23)
        XCTAssertEqual(snapshot.deepSleepMinutes, 71)
        XCTAssertEqual(snapshot.sleepSegments.count, 2)
    }

    func testCommandBuilderFrames() {
        let stepGoalFrame = [UInt8](BMLCommandBuilder.setStepGoal(8000))
        XCTAssertEqual(stepGoalFrame, [0xAB, 0x00, 0x07, 0xFF, 0x74, 0x80, 0x00, 0x00, 0x1F, 0x40])

        let wakeFrame = [UInt8](BMLCommandBuilder.setRaiseWristToWake(enabled: true))
        XCTAssertEqual(wakeFrame, [0xAB, 0x00, 0x04, 0xFF, 0x77, 0x80, 0x01])
    }
}