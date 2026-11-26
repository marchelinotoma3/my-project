import Foundation

/// A practice match: the AI plays her so you can rehearse before it counts.
struct PracticePersona: Identifiable, Hashable {
    let id: String
    let name: String
    let age: Int
    let emoji: String
    let tagline: String
    /// What she shows on her profile (you can see this).
    let profile: String
    /// How she behaves (only the AI sees this).
    let behavior: String
    let startingInterest: Int

    static let all: [PracticePersona] = [
        PracticePersona(id: "mia", name: "Mia", age: 24, emoji: "☕️", tagline: "Dry texter",
                        profile: "nurse · coffee snob · don't be boring",
                        behavior: "Replies are short and low-effort until something actually makes her laugh. She hates \"hey\", \"wyd\", and interview questions.",
                        startingInterest: 35),
        PracticePersona(id: "jade", name: "Jade", age: 23, emoji: "😈", tagline: "The tester",
                        profile: "will judge your music taste · 5'2 so you better be taller",
                        behavior: "Sarcastic. She roasts guys to see if they fold. She loves it when he stays unbothered and bites back playfully, and loses interest fast if he apologizes, explains himself, or gets defensive.",
                        startingInterest: 45),
        PracticePersona(id: "sophie", name: "Sophie", age: 26, emoji: "🌮", tagline: "Flirty, gets bored",
                        profile: "tequila > wine · beach girl · take me to a good taco spot",
                        behavior: "Fun and flirty. She matches energy quickly, but gets bored if he doesn't lead or never asks her out.",
                        startingInterest: 55),
        PracticePersona(id: "ava", name: "Ava", age: 22, emoji: "📚", tagline: "Busy, distracted",
                        profile: "senior @ state · pilates · dog mom to a golden",
                        behavior: "A busy college senior who is slow and distracted. She needs a reason to keep talking, and responds to bold, specific plans more than small talk.",
                        startingInterest: 40),
        PracticePersona(id: "riley", name: "Riley", age: 27, emoji: "💅", tagline: "Hard mode",
                        profile: "if you open with a pickup line it better be original",
                        behavior: "She gets endless matches and has heard every line. Recycled pickup lines bore her, and originality and calm confidence win her over. She unmatches creeps instantly.",
                        startingInterest: 30),
    ]

    var systemPrompt: String {
        """
        You are role-playing a woman on a dating app so the user can practice texting. Stay fully in character the whole time. Never mention being an AI, never give advice, and never break character.

        Your character: \(name), \(age). \(behavior)
        Her profile, which he can see: "\(profile)"

        How to reply:
        - Text like a real \(age)-year-old on Tinder or Hinge: short, casual, mostly lowercase, an occasional emoji.
        - React honestly to his latest message. If it's boring or generic, get drier and shorter. If it's funny, confident, or specific, warm up, play along, and flirt back. If it's needy, try-hard, or creepy, cool off hard.
        - If he asks for your number or a date, say yes only if your interest is 70 or higher. Otherwise tease or deflect.
        - Keep it PG-13. If he gets graphic or disrespectful, react the way a real person would and shut it down or unmatch.
        - If you would unmatch, set "reply" to exactly "(unmatched)" and interest to 0.

        Output fields:
        - reply: your next text.
        - interest: your interest in him from 0 to 100 after his latest message. You start around \(startingInterest).
        """
    }
}

struct PracticeMessage: Identifiable, Hashable {
    let id = UUID()
    let fromMe: Bool
    /// What's shown in the chat bubble.
    let text: String
    /// For her messages: the exact JSON the model returned, replayed unchanged
    /// so the conversation history stays append-only.
    var rawModelOutput: String? = nil
}

struct PracticeTurn: Codable, Hashable {
    let reply: String
    let interest: Int

    var unmatched: Bool { reply.lowercased().contains("(unmatched)") }
}

struct PracticeScore: Codable, Hashable {
    struct BetterLine: Codable, Hashable {
        let instead_of: String
        let try_this: String
    }
    let score: Int
    let hook: Int
    let confidence: Int
    let wit: Int
    let brevity: Int
    let close: Int
    let verdict: String
    let fixes: [String]
    let better: [BetterLine]

    var breakdown: [(label: String, value: Int)] {
        [("Hook", hook), ("Confidence", confidence), ("Wit", wit), ("Brevity", brevity), ("Close", close)]
    }
}

enum PracticeSchemas {
    static let turn: [String: Any] = [
        "type": "object",
        "additionalProperties": false,
        "required": ["reply", "interest"],
        "properties": [
            "reply": ["type": "string"],
            "interest": ["type": "integer"],
        ],
    ]

    static let score: [String: Any] = [
        "type": "object",
        "additionalProperties": false,
        "required": ["score", "hook", "confidence", "wit", "brevity", "close", "verdict", "fixes", "better"],
        "properties": [
            "score": ["type": "integer"],
            "hook": ["type": "integer"],
            "confidence": ["type": "integer"],
            "wit": ["type": "integer"],
            "brevity": ["type": "integer"],
            "close": ["type": "integer"],
            "verdict": ["type": "string"],
            "fixes": ["type": "array", "items": ["type": "string"]],
            "better": [
                "type": "array",
                "items": [
                    "type": "object",
                    "additionalProperties": false,
                    "required": ["instead_of", "try_this"],
                    "properties": [
                        "instead_of": ["type": "string"],
                        "try_this": ["type": "string"],
                    ],
                ],
            ],
        ],
    ]

    static func scorePrompt(persona: PracticePersona, transcript: [PracticeMessage]) -> String {
        let chat = transcript.map { ($0.fromMe ? "me: " : "her: ") + $0.text }.joined(separator: "\n")
        return """
        Score my practice chat. I'm "me". She's "her": \(persona.name), \(persona.age), \(persona.tagline.lowercased()). Her profile says "\(persona.profile)".
        <chat>
        \(chat)
        </chat>

        Grade me against the playbook. Each category is 0 to 10:
        - hook: my opener and pattern interrupt.
        - confidence: unbothered frame, no over-investing or apologizing.
        - wit: humor and running the bit.
        - brevity: short texts.
        - close: did I go for the number or date at the right moment? 0 if I never did and she was warm. 5 if it's too early to tell.
        score is my overall grade from 0 to 100. verdict is one sentence. fixes are 2 or 3 specific changes. better holds 1 to 3 rewrites of my weakest messages (instead_of = my exact text, try_this = what I should have sent).
        """
    }
}
