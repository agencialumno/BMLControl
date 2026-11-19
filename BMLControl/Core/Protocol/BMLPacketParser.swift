import Foundation

enum BMLDecodedEvent: Equatable {
    case battery(level: Int, isCharging: Bool)
    case dailySummary(dateKey: String, steps: Int, calories: Int, deepMinutes: Int, lightMinutes: Int)
    case hourlyVital(
        sampleID: String,
        dateKey: String,
        timestamp: Date,
        hour: Int,
        steps: Int,
        calories: Int,
        heartRate: Int,
        spo2: Int,
        systolicBP: Int,
        diastolicBP: Int
    )
    case hourlyHeartRate(sampleID: String, dateKey: String, timestamp: Date, hour: Int, bpm: Int)
    case sleepSegment(segmentID: String, dateKey: String, startTimestamp: Date, isDeepSleep: Bool, durationMinutes: Int)
    case ack(code: UInt8)
    case heartbeat
    case watchTriggeredFindPhone
    case watchTriggeredCameraShutter
}

struct BMLPacketParseOutput {
    let event: BMLDecodedEvent
    let logDescription: String
}

enum BMLPacketParser {
    static func todayDateKey(for date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 2026, c.month ?? 1, c.day ?? 1)
    }

    static func decode(_ data: Data, referenceDate: Date = Date()) -> BMLPacketParseOutput? {
        let bytes = [UInt8](data)
        guard bytes.count >= 6, bytes[0] == 0xAB, bytes[3] == 0xFF else {
            return nil
        }

        let commandID = bytes[4]
        let subCommand = bytes[5]

        switch (commandID, subCommand) {
        case (0x91, 0x80) where bytes.count >= 8:
            let charging = bytes[6] == 0x01
            let level = Int(bytes[7])
            return BMLPacketParseOutput(
                event: .battery(level: level, isCharging: charging),
                logDescription: "Bateria: \(level)% (\(charging ? "Carregando" : "Uso"))"
            )

        case (0x51, 0x08) where bytes.count >= 16:
            let steps = (Int(bytes[6]) << 16) | (Int(bytes[7]) << 8) | Int(bytes[8])
            let kcal = (Int(bytes[9]) << 16) | (Int(bytes[10]) << 8) | Int(bytes[11])
            let deepMin = Int(bytes[12]) * 60 + Int(bytes[13])
            let lightMin = Int(bytes[14]) * 60 + Int(bytes[15])
            let dateKey = todayDateKey(for: referenceDate)

            return BMLPacketParseOutput(
                event: .dailySummary(
                    dateKey: dateKey,
                    steps: steps,
                    calories: kcal,
                    deepMinutes: deepMin,
                    lightMinutes: lightMin
                ),
                logDescription: "Resumo Diário: \(steps) passos | \(kcal) kcal | Sono \(deepMin + lightMin)m"
            )

        case (0x51, 0x20) where bytes.count >= 20:
            let year = 2000 + Int(bytes[6])
            let month = Int(bytes[7])
            let day = Int(bytes[8])
            let hour = Int(bytes[9])

            let steps = (Int(bytes[10]) << 16) | (Int(bytes[11]) << 8) | Int(bytes[12])
            let kcal = (Int(bytes[13]) << 16) | (Int(bytes[14]) << 8) | Int(bytes[15])
            let hr = Int(bytes[16])
            let spo2 = Int(bytes[17])
            let sbp = Int(bytes[18])
            let dbp = Int(bytes[19])

            let dateKey = String(format: "%04d-%02d-%02d", year, month, day)
            let sampleID = String(format: "%04d-%02d-%02d-%02d", year, month, day, hour)
            let timestamp = Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? referenceDate

            return BMLPacketParseOutput(
                event: .hourlyVital(
                    sampleID: sampleID,
                    dateKey: dateKey,
                    timestamp: timestamp,
                    hour: hour,
                    steps: steps,
                    calories: kcal,
                    heartRate: hr,
                    spo2: spo2,
                    systolicBP: sbp,
                    diastolicBP: dbp
                ),
                logDescription: String(
                    format: "%02d/%02d %02d:00 -> %d passos, FC %d bpm, SpO2 %d%%, PA %d/%d",
                    day, month, hour, steps, hr, spo2, sbp, dbp
                )
            )

        case (0x51, 0x0B) where bytes.count >= 12:
            let year = 2000 + Int(bytes[6])
            let month = Int(bytes[7])
            let day = Int(bytes[8])
            let hour = Int(bytes[9])
            let bpm = Int(bytes[11])

            let dateKey = String(format: "%04d-%02d-%02d", year, month, day)
            let sampleID = String(format: "%04d-%02d-%02d-%02d", year, month, day, hour)
            let timestamp = Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? referenceDate

            return BMLPacketParseOutput(
                event: .hourlyHeartRate(sampleID: sampleID, dateKey: dateKey, timestamp: timestamp, hour: hour, bpm: bpm),
                logDescription: String(format: "FC Horária (%02d/%02d %02d:00): %d bpm", day, month, hour, bpm)
            )

        case (0x52, 0x80) where bytes.count >= 14:
            let year = 2000 + Int(bytes[6])
            let month = Int(bytes[7])
            let day = Int(bytes[8])
            let hour = Int(bytes[9])
            let minute = Int(bytes[10])
            let isDeep = bytes[11] == 0x01
            let duration = (Int(bytes[12]) << 8) | Int(bytes[13])

            let dateKey = String(format: "%04d-%02d-%02d", year, month, day)
            let segmentID = String(format: "%04d-%02d-%02d-%02d-%02d", year, month, day, hour, minute)
            let timestamp = Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? referenceDate

            return BMLPacketParseOutput(
                event: .sleepSegment(
                    segmentID: segmentID,
                    dateKey: dateKey,
                    startTimestamp: timestamp,
                    isDeepSleep: isDeep,
                    durationMinutes: duration
                ),
                logDescription: String(
                    format: "%@ (%02d/%02d %02d:%02d): %d min",
                    isDeep ? "Sono Profundo" : "Sono Leve", day, month, hour, minute, duration
                )
            )

        case (0x7B, 0x80) where bytes.count >= 7:
            return BMLPacketParseOutput(
                event: .ack(code: bytes[6]),
                logDescription: String(format: "ACK confirmado pelo relógio (0x%02X)", bytes[6])
            )

        case (0x21, 0x80):
            return BMLPacketParseOutput(
                event: .heartbeat,
                logDescription: "Heartbeat ativo (0x21)"
            )

        // Evento disparado pelo relógio ao tocar em "Localizar Celular" (0x81 ou 0x71)
        case (0x81, _), (0x71, _):
            return BMLPacketParseOutput(
                event: .watchTriggeredFindPhone,
                logDescription: "Relógio acionou Localizar iPhone!"
            )

        // Evento disparado pelo relógio ao tocar no obturador da Câmera Remota (0x79)
        case (0x79, _):
            return BMLPacketParseOutput(
                event: .watchTriggeredCameraShutter,
                logDescription: "Relógio acionou disparo da Câmera Remota!"
            )

        default:
            return nil
        }
    }
}