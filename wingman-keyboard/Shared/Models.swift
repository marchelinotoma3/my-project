import Foundation

/// How far the suggestions are allowed to push the flirting.
enum Spice: String, CaseIterable, Codable, Identifiable {
    case clean, flirty, spicy

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var emoji: String {
        switch self {
        case .clean: return "😇"
        case .flirty: return "😏"
        case .spicy: return "🌶️"
        }
    }
    var rank: Int {
        switch self {
        case .clean: return 0
        case .flirty: return 1
        case .spicy: return 2
        }
    }
}

/// What kind of reply the user wants right now.
enum Vibe: String, CaseIterable, Codable, Identifiable {
    case auto, funny, flirty, smooth, close, revive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: return "Auto"
        case .funny: return "Funny"
        case .flirty: return "Flirty"
        case .smooth: return "Smooth"
        case .close: return "Get the #"
        case .revive: return "Revive"
        }
    }

    var emoji: String {
        switch self {
        case .auto: return "🎯"
        case .funny: return "😂"
        case .flirty: return "😏"
        case .smooth: return "😎"
        case .close: return "📱"
        case .revive: return "⚡️"
        }
    }

    /// Instruction sent to the model for this vibe.
    var instruction: String {
        switch self {
        case .auto:
            return "Pick whatever the playbook says is the best move right now."
        case .funny:
            return "Lean funny: absurd setups, puns, running the bit."
        case .flirty:
            return "Lean flirty: teasing and tension, matched to her energy."
        case .smooth:
            return "Lean smooth: calm, confident, low-effort charm. No cheesy lines."
        case .close:
            return "Go for the close: get her number or lock in a plan. If she isn't warm enough yet, give one reply that warms it up first, and say so in move."
        case .revive:
            return "The chat has gone quiet or dry. Write a reply that restarts it without sounding needy (callback to an earlier joke, a bold new setup, or a playful call-out)."
        }
    }
}

/// One suggested text to send.
struct Reply: Codable, Hashable, Identifiable {
    var id: String { text }
    let text: String
    let style: String
    let why: String
}

/// The model's read of the conversation plus reply options.
struct Analysis: Codable, Hashable {
    let read: String
    let interest: String
    let move: String
    let replies: [Reply]
    /// Filled in locally, not by the model.
    var createdAt: Date?
    var source: String?

    var interestEmoji: String {
        switch interest.lowercased() {
        case "hot": return "🔥"
        case "warm": return "🙂"
        case "lukewarm": return "😐"
        default: return "🧊"
        }
    }
}

/// A "line of the day": a setup, the reply she'll probably give, and your payoff.
struct DailyLine: Codable, Hashable, Identifiable {
    enum Kind: String, Codable { case opener, comeback, close }

    var id: String { setup }
    let kind: Kind
    let spice: Spice
    /// What you send first.
    let setup: String
    /// What she usually says back ("wym?", "how so?").
    let herReply: String
    /// What you send next.
    let payoff: String

    var kindTitle: String {
        switch kind {
        case .opener: return "Opener"
        case .comeback: return "Comeback"
        case .close: return "Close"
        }
    }
}
