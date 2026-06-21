import Foundation

enum SettingsIntervalUnit {
    case hours
    case days
    case weeks

    static func preferredUnit(forMinutes minutes: Int) -> SettingsIntervalUnit {
        if minutes >= AppSettings.weeklyScanIntervalMinutes,
           minutes % AppSettings.weeklyScanIntervalMinutes == 0,
           (1...4).contains(minutes / AppSettings.weeklyScanIntervalMinutes) {
            return .weeks
        }

        if minutes >= AppSettings.dailyScanIntervalMinutes,
           minutes % AppSettings.dailyScanIntervalMinutes == 0,
           (1...7).contains(minutes / AppSettings.dailyScanIntervalMinutes) {
            return .days
        }

        return .hours
    }
}
