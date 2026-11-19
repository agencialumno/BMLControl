import Foundation

enum BMLCommandBuilder {
    // MARK: - Comandos Validados no Hardware BML X Pro Max 5 (Fases 2 a 4)

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

    static func findWatch(activate: Bool) -> Data {
        return Data([0xAB, 0x00, 0x04, 0xFF, 0x71, 0x80, activate ? 0x01 : 0x00])
    }

    static func setRaiseWristToWake(enabled: Bool) -> Data {
        return Data([0xAB, 0x00, 0x04, 0xFF, 0x77, 0x80, enabled ? 0x01 : 0x00])
    }

    static func set24HourFormat(is24Hour: Bool) -> Data {
        return Data([0xAB, 0x00, 0x04, 0xFF, 0x7C, 0x80, is24Hour ? 0x00 : 0x01])
    }

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

    // MARK: - Comandos de Funções Inteligentes (Hipótese ainda não testada — Validar na Fase 8)

    /// Envia a máscara de permissões de alertas ANCS para o firmware Wearfit (Comando 0x72).
    static func setNotificationMask(_ mask: UInt16) -> Data {
        let hi = UInt8((mask >> 8) & 0xFF)
        let lo = UInt8(mask & 0xFF)
        return Data([0xAB, 0x00, 0x05, 0xFF, 0x72, 0x80, hi, lo])
    }

    /// Configura um alarme no relógio (Comando 0x73: índice 0..2, ativo, hora, minuto, máscara dias).
    static func setAlarm(index: Int, enabled: Bool, hour: Int, minute: Int, repeatMask: UInt8 = 0x7F) -> Data {
        let safeIdx = UInt8(max(0, min(index, 4)))
        let safeHour = UInt8(max(0, min(hour, 23)))
        let safeMin = UInt8(max(0, min(minute, 59)))
        return Data([
            0xAB, 0x00, 0x08, 0xFF, 0x73, 0x80,
            safeIdx,
            enabled ? 0x01 : 0x00,
            safeHour,
            safeMin,
            repeatMask
        ])
    }

    /// Envia condições climáticas atuais para o widget de clima do relógio (Comando 0x7E).
    static func syncWeather(conditionCode: UInt8, currentTemp: Int, minTemp: Int, maxTemp: Int) -> Data {
        let cur = UInt8(bitPattern: Int8(clamping: currentTemp))
        let maxT = UInt8(bitPattern: Int8(clamping: maxTemp))
        let minT = UInt8(bitPattern: Int8(clamping: minTemp))
        return Data([0xAB, 0x00, 0x08, 0xFF, 0x7E, 0x80, conditionCode, cur, maxT, minT, 0x00])
    }

    /// Ativa ou encerra o modo obturador de câmera remota no relógio (Comando 0x79).
    static func setRemoteCameraMode(enabled: Bool) -> Data {
        return Data([0xAB, 0x00, 0x04, 0xFF, 0x79, 0x80, enabled ? 0x01 : 0x00])
    }
}