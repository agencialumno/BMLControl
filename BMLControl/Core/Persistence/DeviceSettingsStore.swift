import Foundation

struct WatchAlarmItem: Identifiable, Codable, Equatable {
    let id: Int // 0, 1, 2
    var isEnabled: Bool
    var hour: Int
    var minute: Int
    var repeatMask: UInt8 // 0x7F = Todos os dias, 0x00 = Uma vez

    var formattedTime: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

@MainActor
final class DeviceSettingsStore: ObservableObject {
    @Published var raiseWristEnabled: Bool {
        didSet { UserDefaults.standard.set(raiseWristEnabled, forKey: Keys.raiseWrist) }
    }
    @Published var is24HourFormat: Bool {
        didSet { UserDefaults.standard.set(is24HourFormat, forKey: Keys.is24Hour) }
    }
    @Published var dailyStepGoal: Int {
        didSet { UserDefaults.standard.set(dailyStepGoal, forKey: Keys.stepGoal) }
    }
    @Published var lastBatteryLevel: Int? {
        didSet {
            if let level = lastBatteryLevel {
                UserDefaults.standard.set(level, forKey: Keys.lastBattery)
            }
        }
    }
    @Published var lastIsCharging: Bool {
        didSet { UserDefaults.standard.set(lastIsCharging, forKey: Keys.lastCharging) }
    }
    @Published var lastSyncDate: Date? {
        didSet { UserDefaults.standard.set(lastSyncDate, forKey: Keys.lastSync) }
    }

    // MARK: - Fase 8: Notificações ANCS, Alarmes e Clima
    @Published var notifyCalls: Bool { didSet { saveNotificationPrefs() } }
    @Published var notifySMS: Bool { didSet { saveNotificationPrefs() } }
    @Published var notifyWhatsApp: Bool { didSet { saveNotificationPrefs() } }
    @Published var notifyInstagram: Bool { didSet { saveNotificationPrefs() } }
    @Published var notifyTelegram: Bool { didSet { saveNotificationPrefs() } }
    @Published var notifyOtherApps: Bool { didSet { saveNotificationPrefs() } }

    @Published var alarms: [WatchAlarmItem] {
        didSet {
            if let encoded = try? JSONEncoder().encode(alarms) {
                UserDefaults.standard.set(encoded, forKey: Keys.alarms)
            }
        }
    }

    @Published var selectedCityID: String {
        didSet { UserDefaults.standard.set(selectedCityID, forKey: Keys.cityID) }
    }

    var selectedCity: WeatherCityPreset {
        WeatherCityPreset.presets.first(where: { $0.id == selectedCityID }) ?? WeatherCityPreset.presets[0]
    }

    /// Calcula a máscara de 16 bits para o comando de notificações Wearfit (0x72).
    var notificationBitmask: UInt16 {
        var mask: UInt16 = 0
        if notifyCalls { mask |= (1 << 0) }
        if notifySMS { mask |= (1 << 1) }
        if notifyWhatsApp { mask |= (1 << 9) }
        if notifyInstagram { mask |= (1 << 10) }
        if notifyTelegram { mask |= (1 << 11) }
        if notifyOtherApps { mask |= (1 << 15) }
        return mask
    }

    private enum Keys {
        static let raiseWrist = "bml_pref_raise_wrist"
        static let is24Hour = "bml_pref_24_hour"
        static let stepGoal = "bml_pref_step_goal"
        static let lastBattery = "bml_state_last_battery"
        static let lastCharging = "bml_state_last_charging"
        static let lastSync = "bml_state_last_sync"
        static let notifMask = "bml_pref_notif_mask"
        static let alarms = "bml_pref_alarms"
        static let cityID = "bml_pref_weather_city"
    }

    init() {
        let defaults = UserDefaults.standard
        self.raiseWristEnabled = defaults.object(forKey: Keys.raiseWrist) as? Bool ?? true
        self.is24HourFormat = defaults.object(forKey: Keys.is24Hour) as? Bool ?? true
        let savedGoal = defaults.integer(forKey: Keys.stepGoal)
        self.dailyStepGoal = savedGoal > 0 ? savedGoal : 8000
        self.lastBatteryLevel = defaults.object(forKey: Keys.lastBattery) as? Int
        self.lastIsCharging = defaults.bool(forKey: Keys.lastCharging)
        self.lastSyncDate = defaults.object(forKey: Keys.lastSync) as? Date

        let savedMask = defaults.object(forKey: Keys.notifMask) as? Int ?? 0xFFFF
        self.notifyCalls = (savedMask & (1 << 0)) != 0
        self.notifySMS = (savedMask & (1 << 1)) != 0
        self.notifyWhatsApp = (savedMask & (1 << 9)) != 0
        self.notifyInstagram = (savedMask & (1 << 10)) != 0
        self.notifyTelegram = (savedMask & (1 << 11)) != 0
        self.notifyOtherApps = (savedMask & (1 << 15)) != 0

        if let data = defaults.data(forKey: Keys.alarms),
           let decoded = try? JSONDecoder().decode([WatchAlarmItem].self, from: data),
           decoded.count == 3 {
            self.alarms = decoded
        } else {
            self.alarms = [
                WatchAlarmItem(id: 0, isEnabled: false, hour: 7, minute: 30, repeatMask: 0x7F),
                WatchAlarmItem(id: 1, isEnabled: false, hour: 9, minute: 0, repeatMask: 0x7F),
                WatchAlarmItem(id: 2, isEnabled: false, hour: 18, minute: 0, repeatMask: 0x7F)
            ]
        }

        self.selectedCityID = defaults.string(forKey: Keys.cityID) ?? "rio"
    }

    private func saveNotificationPrefs() {
        UserDefaults.standard.set(Int(notificationBitmask), forKey: Keys.notifMask)
    }
}