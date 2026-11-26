import AppIntents
import Foundation

/// Shortcuts action: "Get Wingman Replies". Pair it with "Take Screenshot" and
/// Back Tap to scan whatever chat is on screen without leaving it.
struct GetRepliesIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Wingman Replies"
    static var description = IntentDescription(
        "Reads a screenshot of a chat and suggests what to text next. The replies show up in the Wingman keyboard.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Screenshot")
    var screenshot: IntentFile

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let store = SharedStore.shared
        guard let jpeg = ImageTools.jpegForClaude(data: screenshot.data) else {
            throw WingmanIntentError.unreadableImage
        }
        var analysis = try await ClaudeClient(store: store).suggestReplies(
            imageJPEG: jpeg, chatText: nil, draft: nil, vibe: store.vibe, spice: store.spice)
        analysis.source = "back tap"
        store.latestAnalysis = analysis

        let best = analysis.replies.first?.text ?? ""
        let message = "\(analysis.interestEmoji) \(analysis.read) Try: \"\(best)\". Open the keyboard for all \(analysis.replies.count) replies."
        return .result(value: best,
                       dialog: IntentDialog(LocalizedStringResource(stringLiteral: message)))
    }
}

enum WingmanIntentError: Error, CustomLocalizedStringResourceConvertible {
    case unreadableImage

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .unreadableImage: return "Couldn't read that screenshot."
        }
    }
}
