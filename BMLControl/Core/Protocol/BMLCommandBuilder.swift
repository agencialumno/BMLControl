import Foundation

enum BMLCommandBuilder {
    // MARK: - Comandos Validados no Hardware BML X Pro Max 5 (Fases 2 a 4)

    /// Sincroniza data e hora exata do iPhone no relógio (Comando 0x93 — Confirmado).
    static func syncTime(for date: Date = Date()) -> Data {
        let calendar = Calendar.current
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let year = UInt16(c.year ?? 2026)
        return Data([
            0xAB, 0x00, 0x0B, 0xFF, 0x93, 0x80, 0x00,
            UInt8((year >> 8) & 0xFF),
            UInt8(year & 0xFF),
            UInt8(c.month ?? 1),
            UInt8(c.day ?? 1),
            UInt8(c.hour ?? 0),
            UInt8(c.minute ?? 0),
            UInt8(c.second ?? 0)
        ])
    }

    /// Solicita descarga histórica de passos, calorias, vitais e sono desde o início do dia (Comando 0x51 — Confirmado).
    static func syncData(since date: Date = Date()) -> Data {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startOfDay)
        let year = UInt16(c.year ?? 2026)
        return Data([
            0xAB, 0x00, 0x0A, 0xFF, 0x51, 0x80, 0x00,
            UInt8((year >> 8) & 0xFF),
            UInt8(year & 0xFF),
            UInt8(c.month ?? 1),
            UInt8(c.day ?? 1),
            UInt8(c.hour ?? 0),
            UInt8(c.minute ?? 0)
        ])
    }

    /// Aciona ou interrompe o alerta sonoro e vibratório no relógio (Comando 0x71 — Confirmado).
    static func findWatch(activate: Bool) -> Data {
        return Data([0xAB, 0x00, 0x04, 0xFF, 0x71, 0x80, activate ? 0x01 : 0x00])
    }

    /// Ativa ou desativa o gesto de levantar o pulso para acender a tela (Comando 0x77 — Confirmado na Fase 4).
    static func setRaiseWristToWake(enabled: Bool) -> Data {
        return Data([0xAB, 0x00, 0x04, 0xFF, 0x77, 0x80, enabled ? 0x01 : 0x00])
    }

    /// Alterna entre formato 24 horas (0x00) e 12 horas AM/PM (0x01) (Comando 0x7C — Confirmado na Fase 4).
    static func set24HourFormat(is24Hour: Bool) -> Data {
        return Data([0xAB, 0x00, 0x04, 0xFF, 0x7C, 0x80, is24Hour ? 0x00 : 0x01])
    }

    /// Define a meta diária de passos em 4 bytes Big-Endian (Comando 0x74 — Confirmado na Fase 4).
    static func setStepGoal(_ steps: Int) -> Data {
        let clamped = UInt32(max(1000, min(steps, 100_000)))
        return Data([
            0xAB, 0x00, 0x07, 0xFF, 0x74, 0x80,
            UInt8((clamped >> 24) & 0xFF),
            UInt8((clamped >> 16) & 0xFF),
            UInt8((clamped >> 8) & 0xFF),
            UInt8(clamped & 0xFF)
        ])
    }
}