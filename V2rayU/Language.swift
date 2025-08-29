//
//  Language.swift
//  V2rayU
//
//  Created by yanue on 2024/12/19.
//

import SwiftUI

// MARK: - Language Label Enum
enum LanguageLabel: String, CaseIterable {
    case Language
    case Theme
    // general settings
    case LaunchAtLogin
    case CheckForUpdateAutomatically
    case AutoUpdateServersFromSubscriptions
    case AutomaticallySelectFastestServer
    case ShowProxySpeedOnTrayIcon
    case EnableProxyStatistics
    
    
}

enum Language: String, CaseIterable, Identifiable { // 添加 Identifiable
    var id: Self { self } // 使枚举可用于 ForEach
    case en = "English"
    case zhHans = "Simplified Chinese"
    case zhHant = "Traditional Chinese"

    var localeIdentifier: String {
        switch self {
        case .en: return "en"
        case .zhHans: return "zh-Hans"
        case .zhHant: return "zh-Hant"
        }
    }

    init(localeIdentifier: String) {
        switch localeIdentifier {
        case "en": self = .en
        case "zh-Hans": self = .zhHans
        case "zh-Hant": self = .zhHant
        default: self = .en
        }
    }

    var localized: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
}

// MARK: - Language Manager
@MainActor
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var selectedLanguage: Language {
        didSet {
            UserDefaults.standard.set([selectedLanguage.localeIdentifier], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            applyLanguage()
        }
    }

    private var languageBundle: Bundle?
    @Published private(set) var currentLocale: Locale

    init() {
        let storedLocaleIdentifier = UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first ?? "en"
        selectedLanguage = Language(localeIdentifier: storedLocaleIdentifier)
        currentLocale = Locale(identifier: storedLocaleIdentifier)
        applyLanguage()
    }

    private func applyLanguage() {
        if let path = Bundle.main.path(forResource: selectedLanguage.localeIdentifier, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            languageBundle = bundle
        } else {
            languageBundle = Bundle.main
        }
        currentLocale = Locale(identifier: selectedLanguage.localeIdentifier)
    }

    func localizedString(_ key: String) -> String {
        return languageBundle?.localizedString(forKey: key, value: nil, table: nil) ?? key
    }
}

// MARK: - String 扩展
extension String {
    @MainActor
    init(localized key: String) {
        self = LanguageManager.shared.localizedString(key)
    }
    @MainActor
    init(localized label: LanguageLabel) {
        self = LanguageManager.shared.localizedString(label.rawValue)
    }
}


// MARK: - View Extensions
extension View {
    /// 响应式本地化 Text - 使用字符串
    func localized(_ label: String) -> some View {
        LocalizedTextView(key: label)
    }
    
    /// 响应式本地化 Text - 使用枚举
    func localized(_ label: LanguageLabel) -> some View {
        LocalizedTextView(key: label.rawValue)
    }
    
    /// 响应式本地化 Text - 带参数
    func localized(_ label: LanguageLabel, _ arguments: CVarArg...) -> some View {
        LocalizedTextView(key: label.rawValue, arguments: arguments)
    }
    
    /// 获取本地化字符串（用于 Picker 标题等）
    func localizedString(_ label: LanguageLabel) -> String {
        LanguageManager.shared.localizedString(label.rawValue)
    }
}

// MARK: - 响应式本地化 Text View
struct LocalizedTextView: View {
    let key: String
    var arguments: [CVarArg] = []
    
    @ObservedObject var languageManager = LanguageManager.shared
    
    var body: some View {
        let localizedString = languageManager.localizedString(key)
        let finalString = arguments.isEmpty ?
            localizedString :
            String(format: localizedString, arguments: arguments)
        
        Text(finalString)
    }
}
