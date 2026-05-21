import Foundation
import Observation

@Observable
final class LanguageManager: @unchecked Sendable {
    nonisolated(unsafe) static let shared = LanguageManager()

    enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
        case en
        case zhHans = "zh-Hans"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .en: "English"
            case .zhHans: "简体中文"
            }
        }
    }

    private var _currentLanguage: AppLanguage

    var currentLanguage: AppLanguage {
        get { _currentLanguage }
        set {
            _currentLanguage = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: Self.storageKey)
        }
    }

    private static let storageKey = "appLanguage"

    private init() {
        if let stored = UserDefaults.standard.string(forKey: Self.storageKey),
           let lang = AppLanguage(rawValue: stored) {
            _currentLanguage = lang
        } else {
            let preferred = Locale.preferredLanguages.first ?? ""
            _currentLanguage = preferred.hasPrefix("zh") ? .zhHans : .en
        }
    }

    func localizedString(for key: String) -> String {
        let bundle: Bundle
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            bundle = langBundle
        } else {
            bundle = .main
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

func L(_ key: String) -> String {
    LanguageManager.shared.localizedString(for: key)
}
