import Foundation

/// Settings and results shared between the Wingman app and the keyboard,
/// stored in the App Group so both can read them.
final class SharedStore {
    static let shared = SharedStore()

    /// The App Group id, set at build time from Config/Base.xcconfig.
    static let appGroupID: String =
        (Bundle.main.object(forInfoDictionaryKey: "WingmanAppGroup") as? String) ?? ""

    static let defaultModel = "claude-opus-5-5"
    static let modelChoices: [(id: String, label: String)] = [
        ("claude-opus-5-5", "Opus 5.5 (best replies)"),
        ("claude-sonnet-5-5", "Sonnet 5.5 (faster, cheaper)"),
        ("claude-haiku-5-5", "Haiku 5.5 (fastest, cheapest)"),
    ]

    let defaults: UserDefaults

    init(defaults: UserDefaults? = nil) {
        if let defaults {
            self.defaults = defaults
        } else if !Self.appGroupID.isEmpty, let group = UserDefaults(suiteName: Self.appGroupID) {
            self.defaults = group
        } else {
            self.defaults = .standard
        }
    }

    private enum Key {
        static let apiKey = "claudeAPIKey"
        static let model = "claudeModel"
        static let spice = "spice"
        static let vibe = "vibe"
        static let latestAnalysis = "latestAnalysis"
        static let lastSeenAnalysis = "lastSeenAnalysisDate"
        static let freshLines = "freshLines"
        static let freshLinesDay = "freshLinesDay"
    }

    // MARK: Settings

    /// The key typed into the app wins; otherwise the build-time key from Secrets.xcconfig.
    var apiKey: String {
        get {
            let stored = defaults.string(forKey: Key.apiKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !stored.isEmpty { return stored }
            let built = (Bundle.main.object(forInfoDictionaryKey: "ClaudeAPIKey") as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            // An unset build setting shows up as an empty string or as the literal "$(CLAUDE_API_KEY)".
            return built.hasPrefix("$(") ? "" : built
        }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Key.apiKey) }
    }

    var model: String {
        get { defaults.string(forKey: Key.model) ?? Self.defaultModel }
        set { defaults.set(newValue, forKey: Key.model) }
    }

    var spice: Spice {
        get { defaults.string(forKey: Key.spice).flatMap(Spice.init(rawValue:)) ?? .flirty }
        set { defaults.set(newValue.rawValue, forKey: Key.spice) }
    }

    var vibe: Vibe {
        get { defaults.string(forKey: Key.vibe).flatMap(Vibe.init(rawValue:)) ?? .auto }
        set { defaults.set(newValue.rawValue, forKey: Key.vibe) }
    }

    // MARK: Latest scan (written by Back Tap / the app, read by the keyboard)

    var latestAnalysis: Analysis? {
        get {
            guard let data = defaults.data(forKey: Key.latestAnalysis) else { return nil }
            return try? JSONDecoder().decode(Analysis.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Key.latestAnalysis)
            } else {
                defaults.removeObject(forKey: Key.latestAnalysis)
            }
        }
    }

    /// A scan the keyboard hasn't shown yet and that is recent enough to still be about this chat.
    func unseenRecentAnalysis(maxAge: TimeInterval = 15 * 60, now: Date = Date()) -> Analysis? {
        guard let analysis = latestAnalysis, let created = analysis.createdAt else { return nil }
        guard now.timeIntervalSince(created) <= maxAge else { return nil }
        if let seen = defaults.object(forKey: Key.lastSeenAnalysis) as? Date, seen >= created { return nil }
        return analysis
    }

    func markAnalysisSeen(_ analysis: Analysis) {
        if let created = analysis.createdAt { defaults.set(created, forKey: Key.lastSeenAnalysis) }
    }

    // MARK: AI-generated lines of the day (cached per day)

    func freshLines(for day: Int) -> [DailyLine]? {
        guard defaults.integer(forKey: Key.freshLinesDay) == day,
              let data = defaults.data(forKey: Key.freshLines) else { return nil }
        return try? JSONDecoder().decode([DailyLine].self, from: data)
    }

    func saveFreshLines(_ lines: [DailyLine], for day: Int) {
        guard let data = try? JSONEncoder().encode(lines) else { return }
        defaults.set(data, forKey: Key.freshLines)
        defaults.set(day, forKey: Key.freshLinesDay)
    }
}
