import Foundation

struct HourlyVitalRecord: Identifiable, Hashable {
    let id: String
    let timestampLabel: String
    let steps: Int
    let calories: Int
    let heartRate: Int
    let spo2: Int
    let systolicBP: Int
    let diastolicBP: Int
}

struct SleepSegmentRecord: Identifiable, Hashable {
    let id: String
    let startLabel: String
    let isDeepSleep: Bool
    let durationMinutes: Int
}

struct BMLTelemetrySnapshot {
    var batteryLevel: Int?
    var isCharging: Bool?
    var steps: Int?
    var calories: Int?
    var heartRate: Int?
    var spo2: Int?
    var systolicBP: Int?
    var diastolicBP: Int?
    var deepSleepMinutes: Int = 0
    var lightSleepMinutes: Int = 0
    var hourlyRecords: [HourlyVitalRecord] = []
    var sleepSegments: [SleepSegmentRecord] = []
    var lastAckHex: String?
    var lastDecodedSummary: String = "Aguardando pacotes do relógio..."

    var totalSleepFormatted: String {
        let total = deepSleepMinutes + lightSleepMinutes
        guard total > 0 else { return "--" }
        return "\(total / 60)h \(String(format: "%02d", total % 60))m"
    }
}

enum BMLPacketParser {
    /// Decodifica frames recebidos via Notify (6E400003) conforme protocolo confirmado na Fase 2.
    static func parse(_ data: Data, into snapshot: inout BMLTelemetrySnapshot) -> String? {
        let bytes = [UInt8](data)
        guard bytes.count >= 6, bytes[0] == 0xAB, bytes[3] == 0xFF else {
            return nil
        }

        let commandID = bytes[4]
        let subCommand = bytes[5]

        switch (commandID, subCommand) {
        // 1. Bateria e Carregamento: AB 00 05 FF 91 80 [Carga] [Nivel]
        case (0x91, 0x80) where bytes.count >= 8:
            let charging = bytes[6] == 0x01
            let level = Int(bytes[7])
            snapshot.isCharging = charging
            snapshot.batteryLevel = level
            let summary = "Bateria: \(level)% (\(charging ? "Carregando" : "Uso"))"
            snapshot.lastDecodedSummary = summary
            return summary

        // 2. Resumo Diário: AB 00 11 FF 51 08 [Steps 3B] [Kcal 3B] [DeepH] [DeepM] [LightH] [LightM] ...
        case (0x51, 0x08) where bytes.count >= 16:
            let steps = (Int(bytes[6]) << 16) | (Int(bytes[7]) << 8) | Int(bytes[8])
            let kcal = (Int(bytes[9]) << 16) | (Int(bytes[10]) << 8) | Int(bytes[11])
            let deepMin = Int(bytes[12]) * 60 + Int(bytes[13])
            let lightMin = Int(bytes[14]) * 60 + Int(bytes[15])

            snapshot.steps = steps
            snapshot.calories = kcal
            if snapshot.sleepSegments.isEmpty && (deepMin > 0 || lightMin > 0) {
                snapshot.deepSleepMinutes = deepMin
                snapshot.lightSleepMinutes = lightMin
            }

            let summary = "Resumo Diário: \(steps) passos | \(kcal) kcal | Sono \(deepMin + lightMin)m"
            snapshot.lastDecodedSummary = summary
            return summary

        // 3. Snapshot Horário: AB 00 19 FF 51 20 [YY MM DD HH] [Steps 3B] [Kcal 3B] [HR] [SpO2] [SBP] [DBP]
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

            snapshot.steps = steps
            snapshot.calories = kcal
            if hr > 0 { snapshot.heartRate = hr }
            if spo2 > 0 { snapshot.spo2 = spo2 }
            if sbp > 0 && dbp > 0 {
                snapshot.systolicBP = sbp
                snapshot.diastolicBP = dbp
            }

            let recordID = String(format: "%04d-%02d-%02d-%02d", year, month, day, hour)
            let label = String(format: "%02d/%02d %02d:00", day, month, hour)
            let record = HourlyVitalRecord(
                id: recordID,
                timestampLabel: label,
                steps: steps,
                calories: kcal,
                heartRate: hr,
                spo2: spo2,
                systolicBP: sbp,
                diastolicBP: dbp
            )

            if let idx = snapshot.hourlyRecords.firstIndex(where: { $0.id == recordID }) {
                snapshot.hourlyRecords[idx] = record
            } else {
                snapshot.hourlyRecords.append(record)
            }
            snapshot.hourlyRecords.sort { $0.id > $1.id }
            if snapshot.hourlyRecords.count > 48 {
                snapshot.hourlyRecords = Array(snapshot.hourlyRecords.prefix(48))
            }

            let summary = "\(label) -> \(steps) passos, FC \(hr) bpm, SpO2 \(spo2)%, PA \(sbp)/\(dbp)"
            snapshot.lastDecodedSummary = summary
            return summary

        // 4. Amostra Horária de FC: AB 00 0B FF 51 0B [YY MM DD HH] 00 [BPM] ...
        case (0x51, 0x0B) where bytes.count >= 12:
            let bpm = Int(bytes[11])
            if bpm > 0 { snapshot.heartRate = bpm }
            let summary = String(format: "FC Horária (%02d/%02d %02d:00): %d bpm", bytes[8], bytes[7], bytes[9], bpm)
            snapshot.lastDecodedSummary = summary
            return summary

        // 5. Fases do Sono: AB 00 0B FF 52 80 [YY MM DD HH MIN] [Tipo] [Dur 2B]
        case (0x52, 0x80) where bytes.count >= 14:
            let isDeep = bytes[11] == 0x01
            let duration = (Int(bytes[12]) << 8) | Int(bytes[13])
            let segID = String(format: "%02d-%02d-%02d-%02d-%02d", bytes[6], bytes[7], bytes[8], bytes[9], bytes[10])
            let startLabel = String(format: "%02d/%02d %02d:%02d", bytes[8], bytes[7], bytes[9], bytes[10])

            let segment = SleepSegmentRecord(
                id: segID,
                startLabel: startLabel,
                isDeepSleep: isDeep,
                durationMinutes: duration
            )

            if !snapshot.sleepSegments.contains(where: { $0.id == segID }) {
                snapshot.sleepSegments.append(segment)
                snapshot.sleepSegments.sort { $0.id > $1.id }
                snapshot.deepSleepMinutes = snapshot.sleepSegments.filter { $0.isDeepSleep }.reduce(0) { $0 + $1.durationMinutes }
                snapshot.lightSleepMinutes = snapshot.sleepSegments.filter { !$0.isDeepSleep }.reduce(0) { $0 + $1.durationMinutes }
            }

            let stageText = isDeep ? "Sono Profundo" : "Sono Leve"
            let summary = "\(stageText) (\(startLabel)): \(duration) min"
            snapshot.lastDecodedSummary = summary
            return summary

        // 6. Confirmação de Escrita (ACK): AB 00 04 FF 7B 80 [Code]
        case (0x7B, 0x80) where bytes.count >= 7:
            let code = String(format: "0x%02X", bytes[6])
            snapshot.lastAckHex = code
            return "ACK confirmado pelo relógio (\(code))"

        // 7. Heartbeat: AB 00 04 FF 21 80 00
        case (0x21, 0x80):
            return "Heartbeat ativo (0x21)"

        default:
            return nil
        }
    }
}