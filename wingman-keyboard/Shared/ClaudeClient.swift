import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Minimal Claude Messages API client (raw HTTPS; there is no official Swift SDK).
struct ClaudeClient {
    enum ClientError: LocalizedError {
        case missingAPIKey
        case http(status: Int, message: String)
        case refusal
        case truncated
        case emptyResponse
        case badJSON(String)
        case nothingToRead

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Add your Claude API key in the Wingman app (Setup tab)."
            case .http(let status, let message):
                if status == 401 { return "Your API key was rejected. Check it in the Wingman app." }
                if status == 429 { return "Rate limited. Wait a few seconds and try again." }
                if status == 529 || status >= 500 { return "Claude is busy right now. Try again in a moment." }
                return "API error \(status): \(message)"
            case .refusal:
                return "Claude declined to help with this one."
            case .truncated:
                return "The reply got cut off. Try again."
            case .emptyResponse:
                return "Got an empty reply. Try again."
            case .badJSON(let detail):
                return "Couldn't read the reply (\(detail)). Try again."
            case .nothingToRead:
                return "Screenshot the chat first, or copy the messages, then tap Scan."
            }
        }
    }

    static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    static let apiVersion = "2026-10-21"
    static let fallbackBeta = "server-side-fallback-2026-07-01"

    let apiKey: String
    let model: String
    var session: URLSession = .shared

    init(apiKey: String, model: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }

    init(store: SharedStore = .shared) {
        self.init(apiKey: store.apiKey, model: store.model)
    }

    // MARK: Public calls

    /// Reads the conversation (screenshot and/or pasted text) and suggests what to send next.
    func suggestReplies(imageJPEG: Data?,
                        chatText: String?,
                        draft: String?,
                        vibe: Vibe,
                        spice: Spice) async throws -> Analysis {
        let trimmedChat = chatText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard imageJPEG != nil || !trimmedChat.isEmpty else { throw ClientError.nothingToRead }

        var content: [[String: Any]] = []
        if let imageJPEG {
            content.append([
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": imageJPEG.base64EncodedString(),
                ],
            ])
        }
        content.append(["type": "text", "text": Self.repliesPrompt(chatText: trimmedChat, draft: draft, vibe: vibe, spice: spice)])

        let json = try await send(content: content, schema: Playbook.analysisSchema)
        do {
            var analysis = try JSONDecoder().decode(Analysis.self, from: json)
            analysis.createdAt = Date()
            return analysis
        } catch {
            throw ClientError.badJSON(error.localizedDescription)
        }
    }

    /// Writes brand-new lines of the day in the playbook's style.
    func freshLines(count: Int = 5, spice: Spice) async throws -> [DailyLine] {
        let prompt = """
        Spice level: \(spice.rawValue)

        Write \(count) brand-new "lines of the day" in the playbook's style: \(max(count - 2, 1)) openers, 1 comeback (for when she tests him or acts dry), and 1 close (number or date ask).
        For each one give the setup he sends, the reply she'll most likely send back ("wym?", "how so?", or her test), and the payoff he sends next.
        Make them original. Don't reuse well-known pickup lines.
        """
        let json = try await send(content: [["type": "text", "text": prompt]], schema: Playbook.linesSchema)

        struct Wire: Decodable {
            struct Line: Decodable {
                let kind: String
                let setup: String
                let her_reply: String
                let payoff: String
            }
            let lines: [Line]
        }
        do {
            let wire = try JSONDecoder().decode(Wire.self, from: json)
            return wire.lines.map {
                DailyLine(kind: DailyLine.Kind(rawValue: $0.kind) ?? .opener,
                          spice: spice,
                          setup: $0.setup,
                          herReply: $0.her_reply,
                          payoff: $0.payoff)
            }
        } catch {
            throw ClientError.badJSON(error.localizedDescription)
        }
    }

    // MARK: Prompt building

    static func repliesPrompt(chatText: String, draft: String?, vibe: Vibe, spice: Spice) -> String {
        var parts: [String] = []
        parts.append("Spice level: \(spice.rawValue)")
        parts.append("What I want right now: \(vibe.instruction)")
        if !chatText.isEmpty {
            parts.append("""
            Here's the conversation, copied as text. It may not say who sent what, so work it out from context:
            <conversation>
            \(chatText)
            </conversation>
            """)
        }
        if let draft = draft?.trimmingCharacters(in: .whitespacesAndNewlines), !draft.isEmpty {
            parts.append("I've started typing this. Improve it or replace it: \"\(draft)\"")
        }
        parts.append("What should I text next?")
        return parts.joined(separator: "\n\n")
    }

    // MARK: Transport

    /// Fallbacks (re-run on another model if a safety classifier declines) are
    /// available on Opus/Sonnet 5.5 but not on Haiku.
    var supportsServerFallbacks: Bool {
        !model.contains("haiku")
    }

    func requestBody(content: [[String: Any]], schema: [String: Any], includeFallbacks: Bool) -> [String: Any] {
        var body: [String: Any] = [
            "model": model,
            "max_tokens": 16000,
            "system": [[
                "type": "text",
                "text": Playbook.systemPrompt,
                "cache_control": ["type": "ephemeral"],
            ]],
            "messages": [["role": "user", "content": content]],
            "output_config": [
                // Keyboard replies need to be fast; "low" keeps thinking short.
                "effort": "low",
                "format": ["type": "json_schema", "schema": schema],
            ],
        ]
        if includeFallbacks { body["fallbacks"] = "default" }
        return body
    }

    /// Sends the request and returns the bytes of the JSON text block.
    private func send(content: [[String: Any]], schema: [String: Any]) async throws -> Data {
        guard !apiKey.isEmpty else { throw ClientError.missingAPIKey }

        var useFallbacks = supportsServerFallbacks
        var attempt = 0
        while true {
            attempt += 1
            let body = requestBody(content: content, schema: schema, includeFallbacks: useFallbacks)
            var request = URLRequest(url: Self.endpoint)
            request.httpMethod = "POST"
            request.timeoutInterval = 60
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")
            if useFallbacks { request.setValue(Self.fallbackBeta, forHTTPHeaderField: "anthropic-beta") }
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0

            if status == 200 {
                return try Self.extractJSONText(from: data)
            }

            let message = Self.errorMessage(from: data)
            // If this account or model doesn't accept the fallbacks option, retry once without it.
            if status == 400, useFallbacks, message.lowercased().contains("fallback") {
                useFallbacks = false
                continue
            }
            // Retry once on overload / rate limit / server errors.
            if attempt < 2, status == 429 || status == 529 || status >= 500 {
                try await Task.sleep(nanoseconds: 1_500_000_000)
                continue
            }
            throw ClientError.http(status: status, message: message)
        }
    }

    static func extractJSONText(from data: Data) throws -> Data {
        struct MessageResponse: Decodable {
            struct Block: Decodable {
                let type: String
                let text: String?
            }
            let content: [Block]
            let stop_reason: String?
        }
        let message: MessageResponse
        do {
            message = try JSONDecoder().decode(MessageResponse.self, from: data)
        } catch {
            throw ClientError.badJSON("unexpected response shape")
        }
        switch message.stop_reason {
        case "refusal": throw ClientError.refusal
        case "max_tokens": throw ClientError.truncated
        default: break
        }
        // Responses can start with thinking blocks; take the text block.
        guard let text = message.content.first(where: { $0.type == "text" })?.text,
              let json = text.data(using: .utf8), !json.isEmpty else {
            throw ClientError.emptyResponse
        }
        return json
    }

    static func errorMessage(from data: Data) -> String {
        struct ErrorEnvelope: Decodable {
            struct Inner: Decodable { let message: String }
            let error: Inner
        }
        if let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data) {
            return envelope.error.message
        }
        return String(data: data, encoding: .utf8) ?? "unknown error"
    }
}
