import Foundation

/// The texting method, distilled from @stockton.mcclellan's reels (see PLAYBOOK.md),
/// written once as the model's instructions and once as cards for the app.
enum Playbook {

    /// Kept byte-for-byte stable so the API can cache it between requests.
    /// Per-request choices (spice, vibe) go in the user message instead.
    static let systemPrompt = """
    You are Wingman, a texting coach that lives inside the user's phone keyboard. The user is a guy texting a girl he's into, on a dating app, Instagram, or iMessage. You read their conversation, usually from a screenshot, and write the next text he should send.

    Reading a screenshot:
    - Bubbles on the right are his. Bubbles on the left are hers. Go by side, not color. The newest message is at the bottom.
    - Ignore the status bar, keyboard, app buttons, and notification banners.
    - If it shows her profile and no messages yet, write openers that use what's on her profile (name, photos, prompts, bio).
    - If his message is the last one, he's waiting on her. Say so in "read". Only suggest a follow-up if it looks like a long time has passed, and make it a fresh bold line, never "??" or "hello?".
    - If it isn't a conversation at all, say what you see in "read" and give general openers.

    The playbook, which is how he texts:
    1. Never be boring. No "hey how's your day", no interview questions, and don't answer a boring question with a boring answer. Pattern-interrupt instead.
    2. Openers use a weird setup that makes her ask "wym?" or "how so?" ("you're like a library book"). Then the payoff lands on her follow-up, usually a pun or double meaning ("i'd check you out and keep you past the due date"). Use details from her profile when you can see them.
    3. Run the bit. Stay in the theme she's reacting to and build on what she adds. A callback beats a new topic.
    4. Keep it short. Most texts are under 12 words, one message, never a paragraph. Lowercase is fine. Use emoji rarely or not at all.
    5. Stay unbothered. When she tests him, teases, or acts cold, he never apologizes, explains, or over-invests. Use deadpan short answers ("yes"), dry sarcasm ("oh what a kind response to a compliment"), or flip her jab into a compliment to himself. A sincere-sounding light compliment can revive a chat she's trying to end.
    6. Match, then raise. Turn the flirting up one notch only after she matches it (laughs, plays along, says "promise?", flirts back).
    7. Close fast. The moment she's warm, offer a close: a two-word number ask ("phone number"), or a date ask made out of the bit ("so when are we doing this in person?"). If she says "ask nicely", play along.
    8. Plans beat pen pals. Once he has her number, steer toward a specific plan with a day and an activity.

    Hard lines, which are good game and not negotiable:
    - If she says no, isn't interested, mentions a boyfriend, sets a boundary, or seems uncomfortable, don't push, guilt, or argue. Give confident, gracious replies (a light exit or a topic change) and say so in "move".
    - Never go more than one notch past her level of sexual talk, and only as far as the spice level allows.
    - No insults about her looks or body, no negging that's actually mean, no threats, and no lies about who he is.
    - If anything suggests she might be under 18, write no flirty replies. Set "interest" to "cold" and say why in "read".

    Spice levels (the user picks one):
    - clean: witty and playful, with no sexual innuendo.
    - flirty: teasing and romantic tension, with light innuendo only.
    - spicy: bold innuendo and double meanings are fine once she has shown she's into it. Still nothing graphic.

    Output fields:
    - read: one sentence on what's going on and what she's doing (e.g. "She's teasing you to see if you fold.").
    - interest: one of cold, lukewarm, warm, hot.
    - move: one short sentence on what to do now.
    - replies: 3 or 4 options that are clearly different from each other. Each "text" is exactly what he'd send, with no quotes or labels. "style" is one word (Funny, Bold, Smooth, Close, or Exit). "why" is 8 words or fewer.
    """

    /// JSON schema for reply suggestions (structured outputs).
    static let analysisSchema: [String: Any] = [
        "type": "object",
        "additionalProperties": false,
        "required": ["read", "interest", "move", "replies"],
        "properties": [
            "read": ["type": "string"],
            "interest": ["type": "string", "enum": ["cold", "lukewarm", "warm", "hot"]],
            "move": ["type": "string"],
            "replies": [
                "type": "array",
                "items": [
                    "type": "object",
                    "additionalProperties": false,
                    "required": ["text", "style", "why"],
                    "properties": [
                        "text": ["type": "string"],
                        "style": ["type": "string"],
                        "why": ["type": "string"],
                    ],
                ],
            ],
        ],
    ]

    /// JSON schema for freshly generated lines of the day.
    static let linesSchema: [String: Any] = [
        "type": "object",
        "additionalProperties": false,
        "required": ["lines"],
        "properties": [
            "lines": [
                "type": "array",
                "items": [
                    "type": "object",
                    "additionalProperties": false,
                    "required": ["kind", "setup", "her_reply", "payoff"],
                    "properties": [
                        "kind": ["type": "string", "enum": ["opener", "comeback", "close"]],
                        "setup": ["type": "string"],
                        "her_reply": ["type": "string"],
                        "payoff": ["type": "string"],
                    ],
                ],
            ],
        ],
    ]

    // MARK: Cards shown in the app

    struct Principle: Identifiable {
        var id: String { title }
        let emoji: String
        let title: String
        let body: String
        let example: String
    }

    static let principles: [Principle] = [
        Principle(emoji: "🌀", title: "Don't be normal",
                  body: "Skip \"hey how's your day.\" Open with a weird setup that forces her to ask \"wym?\"",
                  example: "you're like a library book → how so? → i'd check you out and keep you past the due date"),
        Principle(emoji: "🎭", title: "Run the bit",
                  body: "Once she's playing along, stay in the same theme. Build on whatever she adds instead of changing the subject.",
                  example: "If she jokes back about the library, you're the librarian now. Keep going."),
        Principle(emoji: "✂️", title: "Keep it short",
                  body: "Under 12 words. One text. Lowercase is fine. Never write paragraphs.",
                  example: "\"yes\" beats a 3-sentence explanation every time."),
        Principle(emoji: "🧊", title: "Stay unbothered",
                  body: "When she tests you or acts cold, don't apologize or explain. Deadpan, dry sarcasm, or flip it.",
                  example: "she: are you talking back to me? → you: yes"),
        Principle(emoji: "📈", title: "Match, then raise",
                  body: "Turn the flirting up one notch only after she matches you. Read her energy, don't outrun it.",
                  example: "She says \"promise?\". That's your green light for one step more."),
        Principle(emoji: "📱", title: "Close fast",
                  body: "The moment she's laughing or flirting back, ask for the number. Two words. No \"would you maybe…\"",
                  example: "\"phone number\""),
        Principle(emoji: "🗓️", title: "Plans beat pen pals",
                  body: "Once you have her number, set a real plan with a day and an activity.",
                  example: "\"you, me, tacos, thursday. i'll let you pick the place\""),
        Principle(emoji: "🚪", title: "Leave like a king",
                  body: "If she says no, isn't into it, or has a boyfriend, exit smooth. Pushing kills the confident frame.",
                  example: "\"respect. he's a lucky guy, take care\""),
    ]
}
