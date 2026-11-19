import Foundation

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

    private enum Keys {
        static let raiseWrist = "bml_pref_raise_wrist"
        static let is24Hour = "bml_pref_24_hour"
        static let stepGoal = "bml_pref_step_goal"
        static let lastBattery = "bml_state_last_battery"
        static let lastCharging = "bml_state_last_charging"
        static let lastSync = "bml_state_last_sync"
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
    }
}