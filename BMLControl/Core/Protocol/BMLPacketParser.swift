import Foundation

struct BMLTelemetrySnapshot {
    var batteryLevel: Int?
    var isCharging: Bool?
    var steps: Int?
    var calories: Int?
    var heartRate: Int?
    var spo2: Int?
    var systolicBP: Int?
    var diastolicBP: Int?
    var lastDecodedSummary: String = "Aguardando pacotes do relógio..."
}

enum BMLPacketParser {
    /// Decodifica um pacote recebido via Notify (6E400003) conforme especificação confirmada na Fase 2.
    static func parse(_ data: Data, into snapshot: inout BMLTelemetrySnapshot) -> String? {
        let bytes = [UInt8](data)
        guard bytes.count >= 6, bytes[0] == 0xAB, bytes[3] == 0xFF else {
            return nil
        }

        let commandID = bytes[4]
        let subCommand = bytes[5]

        switch (commandID, subCommand) {
        // 1. Bateria e Estado de Carga: AB 00 05 FF 91 80 [Carga] [Nivel]
        case (0x91, 0x80) where bytes.count >= 8:
            let charging = bytes[6] == 0x01
            let level = Int(bytes[7])
            snapshot.isCharging = charging
            snapshot.batteryLevel = level
            let summary = "Bateria: \(level)% (\(charging ? "Carregando" : "Bateria"))"
            snapshot.lastDecodedSummary = summary
            return summary

        // 2. Resumo Diário (Passos, Calorias, Sono): AB 00 11 FF 51 08 [Steps 3B] [Kcal 3B] ...
        case (0x51, 0x08) where bytes.count >= 12:
            let steps = (Int(bytes[6]) << 16) | (Int(bytes[7]) << 8) | Int(bytes[8])
            let kcal = (Int(bytes[9]) << 16) | (Int(bytes[10]) << 8) | Int(bytes[11])
            snapshot.steps = steps
            snapshot.calories = kcal
            let summary = "Resumo Diário: \(steps) passos | \(kcal) kcal"
            snapshot.lastDecodedSummary = summary
            return summary

        // 3. Snapshot Horário de Atividade e Vitais: AB 00 19 FF 51 20 [YY MM DD HH] [Steps 3B] [Kcal 3B] [HR] [SpO2] [SBP] [DBP]
        case (0x51, 0x20) where bytes.count >= 20:
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

            let summary = String(
                format: "Hora %02d:00 -> %d passos, %d kcal, FC %d bpm, SpO2 %d%%, PA %d/%d",
                bytes[9], steps, kcal, hr, spo2, sbp, dbp
            )
            snapshot.lastDecodedSummary = summary
            return summary

        // 4. Amostra Horária de Frequência Cardíaca: AB 00 0B FF 51 0B [YY MM DD HH] 00 [BPM] ...
        case (0x51, 0x0B) where bytes.count >= 12:
            let bpm = Int(bytes[11])
            if bpm > 0 { snapshot.heartRate = bpm }
            let summary = String(format: "FC Horária (%02d:00): %d bpm", bytes[9], bpm)
            snapshot.lastDecodedSummary = summary
            return summary

        // 5. Registro de Sono: AB 00 0B FF 52 80 [YY MM DD HH MIN] [Tipo] [Dur 2B]
        case (0x52, 0x80) where bytes.count >= 14:
            let stage = bytes[11] == 0x01 ? "Sono Profundo" : "Sono Leve"
            let duration = (Int(bytes[12]) << 8) | Int(bytes[13])
            let summary = String(format: "%@ (%02d:%02d): %d min", stage, bytes[9], bytes[10], duration)
            snapshot.lastDecodedSummary = summary
            return summary

        // 6. Confirmação de Comando (Ack): AB 00 04 FF 7B 80 04
        case (0x7B, 0x80):
            return "Confirmação do relógio recebida (ACK 0x7B)"

        // 7. Heartbeat: AB 00 04 FF 21 80 00
        case (0x21, 0x80):
            return "Heartbeat ativo (0x21)"

        default:
            return nil
        }
    }

    /// Constrói o pacote de sincronização de data e hora atual (Comando 0x93 confirmado).
    static func buildSyncTimeCommand(for date: Date = Date()) -> Data {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let year = UInt16(components.year ?? 2026)
        let yearHi = UInt8((year >> 8) & 0xFF)
        let yearLo = UInt8(year & 0xFF)
        let month = UInt8(components.month ?? 1)
        let day = UInt8(components.day ?? 1)
        let hour = UInt8(components.hour ?? 0)
        let minute = UInt8(components.minute ?? 0)
        let second = UInt8(components.second ?? 0)

        return Data([0xAB, 0x00, 0x0B, 0xFF, 0x93, 0x80, 0x00, yearHi, yearLo, month, day, hour, minute, second])
    }

    /// Constrói o pacote de solicitação de histórico do dia atual (Comando 0x51 confirmado).
    static func buildSyncTodayDataCommand(for date: Date = Date()) -> Data {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.year, .month, .day], from: startOfDay)
        let year = UInt16(components.year ?? 2026)
        let yearHi = UInt8((year >> 8) & 0xFF)
        let yearLo = UInt8(year & 0xFF)
        let month = UInt8(components.month ?? 1)
        let day = UInt8(components.day ?? 1)

        return Data([0xAB, 0x00, 0x0A, 0xFF, 0x51, 0x80, 0x00, yearHi, yearLo, month, day, 0x00, 0x00])
    }

    /// Constrói o comando Encontrar Relógio (Comando 0x71 confirmado).
    static func buildFindWatchCommand(activate: Bool) -> Data {
        return Data([0xAB, 0x00, 0x04, 0xFF, 0x71, 0x80, activate ? 0x01 : 0x00])
    }
}