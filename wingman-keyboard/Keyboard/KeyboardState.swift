import UIKit
import SwiftUI

/// All keyboard behavior: typing, scanning, suggestions, lines of the day.
@MainActor
final class KeyboardState: ObservableObject {
    enum Panel { case keys, replies, lines, vibes }
    enum KeySet { case letters, numbers, symbols }
    enum Shift { case off, once, locked }
    enum Status: Equatable {
        case idle
        case hint(String)
        case working(String)
        case error(String)
    }

    @Published var panel: Panel = .keys
    @Published var keySet: KeySet = .letters
    @Published var shift: Shift = .off
    @Published var status: Status = .idle
    @Published var analysis: Analysis?
    @Published var lines: [DailyLine] = []
    @Published var screenshotReady = false
    @Published var loadingFreshLines = false
    @Published var vibe: Vibe = .auto
    @Published var spice: Spice = .flirty

    private weak var controller: KeyboardViewController?
    private let store = SharedStore.shared
    private var deleteTask: Task<Void, Never>?
    private var lastShiftTap = Date.distantPast
    private var lastSpaceTap = Date.distantPast
    /// The text that was in the box when we scanned. A picked reply replaces it.
    private var draftAtScan: String?

    init(controller: KeyboardViewController) {
        self.controller = controller
    }

    private var proxy: UITextDocumentProxy? { controller?.textDocumentProxy }
    var hasFullAccess: Bool { controller?.hasFullAccess ?? false }
    var needsGlobeKey: Bool { controller?.needsInputModeSwitchKey ?? true }

    // MARK: Lifecycle

    func refreshOnAppear() {
        spice = store.spice
        vibe = store.vibe
        reloadLines()

        if let fresh = store.unseenRecentAnalysis() {
            analysis = fresh
            store.markAnalysisSeen(fresh)
            status = .hint("Your Back Tap scan is ready. Tap a reply to drop it in.")
        } else if !hasFullAccess {
            status = .hint("Turn on Allow Full Access to use Scan (open the Wingman app › Setup).")
        } else if ScreenshotFinder.latestScreenshot(maxAge: 5 * 60) != nil {
            screenshotReady = true
            status = .hint("Got your screenshot. Tap Scan.")
        } else if analysis == nil {
            status = .hint("Screenshot the chat, then tap Scan.")
        }
        textDidChange()
    }

    func textDidChange() {
        updateAutoCapitalization()
    }

    // MARK: Typing

    var letterRows: [[String]] {
        switch keySet {
        case .letters:
            return [Array("qwertyuiop"), Array("asdfghjkl"), Array("zxcvbnm")].map { $0.map(String.init) }
        case .numbers:
            return [Array("1234567890"), Array("-/:;()$&@\""), Array(".,?!'")].map { $0.map(String.init) }
        case .symbols:
            return [Array("[]{}#%^*+="), Array("_\\|~<>€£¥•"), Array(".,?!'")].map { $0.map(String.init) }
        }
    }

    func display(_ key: String) -> String {
        keySet == .letters && shift != .off ? key.uppercased() : key
    }

    func type(_ key: String) {
        proxy?.insertText(display(key))
        if shift == .once { shift = .off }
    }

    func space() {
        let now = Date()
        // Double-tap space → ". " like the system keyboard.
        if now.timeIntervalSince(lastSpaceTap) < 0.35,
           let before = proxy?.documentContextBeforeInput,
           before.hasSuffix(" "),
           let previous = before.dropLast().last,
           previous.isLetter || previous.isNumber {
            proxy?.deleteBackward()
            proxy?.insertText(". ")
            lastSpaceTap = .distantPast
        } else {
            proxy?.insertText(" ")
            lastSpaceTap = now
        }
        if keySet != .letters { keySet = .letters }
    }

    func newline() {
        proxy?.insertText("\n")
    }

    func tapShift() {
        let now = Date()
        if shift == .locked {
            shift = .off
        } else if now.timeIntervalSince(lastShiftTap) < 0.3 {
            shift = .locked
        } else {
            shift = (shift == .off) ? .once : .off
        }
        lastShiftTap = now
    }

    func toggleNumbers() {
        keySet = (keySet == .letters) ? .numbers : .letters
    }

    func toggleSymbols() {
        keySet = (keySet == .symbols) ? .numbers : .symbols
    }

    func nextKeyboard() {
        controller?.advanceToNextInputMode()
    }

    func deletePressed() {
        guard deleteTask == nil else { return }
        proxy?.deleteBackward()
        deleteTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 450_000_000)
            while !Task.isCancelled {
                self?.proxy?.deleteBackward()
                try? await Task.sleep(nanoseconds: 70_000_000)
            }
        }
    }

    func deleteReleased() {
        deleteTask?.cancel()
        deleteTask = nil
        updateAutoCapitalization()
    }

    private func updateAutoCapitalization() {
        guard shift != .locked else { return }
        guard let proxy, proxy.autocapitalizationType != UITextAutocapitalizationType.none else {
            if shift == .once { shift = .off }
            return
        }
        let before = proxy.documentContextBeforeInput ?? ""
        let trimmed = before.trimmingCharacters(in: .whitespaces)
        let startOfSentence = before.isEmpty
            || before.hasSuffix("\n")
            || (before.hasSuffix(" ") && [".", "!", "?"].contains(trimmed.last.map(String.init) ?? ""))
        shift = startOfSentence ? .once : .off
    }

    // MARK: Panels

    func toggle(_ target: Panel) {
        panel = (panel == target) ? .keys : target
    }

    func setVibe(_ newVibe: Vibe) {
        vibe = newVibe
        store.vibe = newVibe
    }

    func setSpice(_ newSpice: Spice) {
        spice = newSpice
        store.spice = newSpice
        reloadLines()
    }

    // MARK: Scan

    func scan() {
        Task { await performScan() }
    }

    private func performScan() async {
        if case .working = status { return }
        guard hasFullAccess else {
            status = .error("Scan needs Full Access: Settings › General › Keyboard › Keyboards › Wingman › Allow Full Access.")
            return
        }
        guard !store.apiKey.isEmpty else {
            status = .error(ClaudeClient.ClientError.missingAPIKey.errorDescription ?? "Add your API key in the Wingman app.")
            return
        }

        status = .working("Reading the chat…")

        // 1) newest screenshot, 2) image on the clipboard, 3) copied text.
        var imageJPEG: Data?
        var source = ""
        if let asset = ScreenshotFinder.latestScreenshot(maxAge: 10 * 60) {
            imageJPEG = await ScreenshotFinder.loadJPEG(for: asset)
            source = "screenshot"
        }
        let pasteboard = UIPasteboard.general
        if imageJPEG == nil, pasteboard.hasImages, let image = pasteboard.image {
            imageJPEG = ImageTools.jpegForClaude(image)
            source = "copied image"
        }
        var chatText: String?
        if imageJPEG == nil, pasteboard.hasStrings {
            chatText = pasteboard.string
            source = "copied text"
        }

        guard imageJPEG != nil || !(chatText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            status = .error(ScreenshotFinder.isAuthorized
                ? "No recent screenshot. Screenshot the chat (or copy the messages), then tap Scan."
                : "Can't see your screenshots yet. Open the Wingman app › Setup › Allow Photos, or copy the messages and tap Scan.")
            return
        }

        let draft = String((proxy?.documentContextBeforeInput ?? "").suffix(300))
        status = .working("Checking the vibe…")

        do {
            var result = try await ClaudeClient(store: store).suggestReplies(
                imageJPEG: imageJPEG, chatText: chatText, draft: draft, vibe: vibe, spice: spice)
            result.source = source
            analysis = result
            store.latestAnalysis = result
            store.markAnalysisSeen(result)
            draftAtScan = draft.isEmpty ? nil : draft
            screenshotReady = false
            status = .idle
            panel = .replies
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    /// Puts a suggestion in the text box, replacing what was typed before the scan.
    func insert(_ text: String) {
        guard let proxy else { return }
        if let draft = draftAtScan, let before = proxy.documentContextBeforeInput, before.hasSuffix(draft) {
            for _ in 0..<draft.count { proxy.deleteBackward() }
        } else if let last = proxy.documentContextBeforeInput?.last, !last.isWhitespace {
            proxy.insertText(" ")
        }
        proxy.insertText(text)
        draftAtScan = nil
        panel = .keys
        if case .error = status { status = .idle }
    }

    // MARK: Lines of the day

    private func reloadLines() {
        let day = LinesOfTheDay.dayNumber()
        lines = LinesOfTheDay.today(spice: spice) + (store.freshLines(for: day) ?? [])
    }

    func writeFreshLines() {
        guard !loadingFreshLines else { return }
        guard hasFullAccess else {
            status = .error("Fresh lines need Full Access: Settings › General › Keyboard › Keyboards › Wingman.")
            return
        }
        loadingFreshLines = true
        Task {
            defer { loadingFreshLines = false }
            do {
                let fresh = try await ClaudeClient(store: store).freshLines(spice: spice)
                store.saveFreshLines(fresh, for: LinesOfTheDay.dayNumber())
                reloadLines()
            } catch {
                status = .error(error.localizedDescription)
            }
        }
    }
}
