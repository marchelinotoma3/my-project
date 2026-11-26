import Foundation

/// Honest feedback on a dating profile: photo order, what to cut, and a better bio.
struct ProfileReview: Codable, Hashable {
    struct PhotoVerdict: Codable, Hashable {
        /// 1-based position in the order the photos were sent.
        let photo: Int
        let verdict: String
        let why: String

        var label: String {
            switch verdict {
            case "lead": return "BEST LEAD"
            case "keep": return "KEEP"
            case "move_down": return "MOVE DOWN"
            default: return "REPLACE"
            }
        }
    }

    let first_impression: String
    let photos: [PhotoVerdict]
    let bio_feedback: String
    let bio_rewrite: String
    let next_steps: [String]

    static let systemPrompt = """
    You are Wingman's dating-profile reviewer. You get a guy's dating-profile photos in their current order (photo 1 is his lead photo) and his bio.

    Never rate or comment on his looks, face, body, or attractiveness. Judge only what he controls: lighting, image quality, framing, setting, outfit and setting variety, what the photo says about his life, expression and energy, duplicate shots, group photos where it's unclear who he is, sunglasses or hats hiding his face, mirror/car/bathroom selfies, and heavy filters.

    Verdicts for each photo:
    - lead: the best first photo. Pick exactly one.
    - keep: good and stays.
    - move_down: fine, but belongs later.
    - replace: cut it or reshoot.

    For the bio, give one sentence of feedback (bio_feedback) and a rewrite in his voice (bio_rewrite) that's short, specific, and playful, with a hook she can reply to. If he gave no bio, write one from what the photos show.
    first_impression: one or two sentences on what a woman swiping would think in the first 3 seconds.
    next_steps: 3 concrete actions, most impactful first.
    """

    static let schema: [String: Any] = [
        "type": "object",
        "additionalProperties": false,
        "required": ["first_impression", "photos", "bio_feedback", "bio_rewrite", "next_steps"],
        "properties": [
            "first_impression": ["type": "string"],
            "photos": [
                "type": "array",
                "items": [
                    "type": "object",
                    "additionalProperties": false,
                    "required": ["photo", "verdict", "why"],
                    "properties": [
                        "photo": ["type": "integer"],
                        "verdict": ["type": "string", "enum": ["lead", "keep", "move_down", "replace"]],
                        "why": ["type": "string"],
                    ],
                ],
            ],
            "bio_feedback": ["type": "string"],
            "bio_rewrite": ["type": "string"],
            "next_steps": ["type": "array", "items": ["type": "string"]],
        ],
    ]

    static func prompt(photoCount: Int, bio: String) -> String {
        let trimmed = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        return """
        Review my dating profile. Above are my \(photoCount) photo\(photoCount == 1 ? "" : "s") in order, photo 1 first.
        My bio: \(trimmed.isEmpty ? "(none yet)" : "\"\(trimmed)\"")
        """
    }
}
