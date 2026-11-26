import SwiftUI
import UIKit

@MainActor
final class PracticeModel: ObservableObject {
    @Published var persona: PracticePersona?
    @Published var messages: [PracticeMessage] = []
    @Published var interest = 0
    @Published var draft = ""
    @Published var waiting = false
    @Published var unmatched = false
    @Published var hints: [Reply] = []
    @Published var loadingHints = false
    @Published var score: PracticeScore?
    @Published var showScore = false
    @Published var scoring = false
    @Published var error: String?

    private var client: ClaudeClient { ClaudeClient(store: .shared) }

    var canScore: Bool { messages.contains { $0.fromMe } && !scoring && !waiting }
    var awaitingHer: Bool { messages.last?.fromMe == true }

    func start(_ newPersona: PracticePersona) {
        persona = newPersona
        messages = []
        interest = newPersona.startingInterest
        unmatched = false
        hints = []
        score = nil
        error = nil
        draft = ""
    }

    func endMatch() {
        persona = nil
        messages = []
    }

    func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !waiting, !unmatched else { return }
        draft = ""
        hints = []
        messages.append(PracticeMessage(fromMe: true, text: text))
        await herTurn()
    }

    /// Asks for her reply to whatever you've sent (also used to retry after an error).
    func herTurn() async {
        guard let persona, awaitingHer, !waiting else { return }
        waiting = true
        error = nil
        defer { waiting = false }
        do {
            let (turn, raw) = try await client.practiceReply(persona: persona, transcript: messages)
            messages.append(PracticeMessage(fromMe: false, text: turn.reply, rawModelOutput: raw))
            interest = max(0, min(100, turn.interest))
            if turn.unmatched { unmatched = true }
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Asks the Wingman coach what to send next in this practice chat.
    func getHints() async {
        guard let persona, !loadingHints else { return }
        loadingHints = true
        error = nil
        defer { loadingHints = false }
        var chat = "(She's \(persona.name), \(persona.age). Her profile: \"\(persona.profile)\")\n"
        chat += messages.map { ($0.fromMe ? "me: " : "her: ") + $0.text }.joined(separator: "\n")
        if messages.isEmpty { chat += "(no messages yet, I need an opener)" }
        do {
            let analysis = try await client.suggestReplies(imageJPEG: nil, chatText: chat, draft: draft,
                                                           vibe: .auto, spice: SharedStore.shared.spice)
            hints = analysis.replies
        } catch {
            self.error = error.localizedDescription
        }
    }

    func scoreChat() async {
        guard let persona, canScore else { return }
        scoring = true
        error = nil
        defer { scoring = false }
        do {
            score = try await client.scorePractice(persona: persona, transcript: messages)
            showScore = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct PracticeView: View {
    @StateObject private var model = PracticeModel()

    var body: some View {
        NavigationStack {
            Group {
                if let persona = model.persona {
                    PracticeChatView(model: model, persona: persona)
                } else {
                    PersonaPicker(model: model)
                }
            }
            .navigationTitle(model.persona.map { "\($0.emoji) \($0.name), \($0.age)" } ?? "Practice")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $model.showScore) {
                if let score = model.score {
                    ScoreSheet(score: score)
                }
            }
        }
    }
}

private struct PersonaPicker: View {
    @ObservedObject var model: PracticeModel

    var body: some View {
        List {
            Section {
                Text("Practice on an AI match before it counts. She reacts like a real person: boring texts dry her up, and confidence warms her up. When you're done, tap Score me.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Section("Pick your match") {
                ForEach(PracticePersona.all) { persona in
                    Button { model.start(persona) } label: {
                        HStack(spacing: 12) {
                            Text(persona.emoji).font(.largeTitle)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(persona.name), \(persona.age) · \(persona.tagline)")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\"\(persona.profile)\"")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

private struct PracticeChatView: View {
    @ObservedObject var model: PracticeModel
    let persona: PracticePersona

    var body: some View {
        VStack(spacing: 0) {
            InterestMeter(value: model.interest)
                .padding(.horizontal)
                .padding(.vertical, 8)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        Text("You matched with \(persona.name). Her profile: \"\(persona.profile)\"")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                        ForEach(model.messages) { message in
                            Bubble(text: message.text, fromMe: message.fromMe)
                                .id(message.id)
                        }
                        if model.waiting {
                            HStack {
                                Text("\(persona.name) is typing…").font(.caption).foregroundStyle(.secondary)
                                Spacer()
                            }
                            .id("typing")
                        }
                        if model.unmatched {
                            Text("💔 \(persona.name) unmatched. Tap Score me to see why.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Brand.accent)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: model.messages.count) { _, _ in
                    if let last = model.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            if let error = model.error {
                HStack {
                    Text(error).font(.footnote).foregroundStyle(.red)
                    if model.awaitingHer {
                        Button("Retry") { Task { await model.herTurn() } }.font(.footnote.weight(.semibold))
                    }
                }
                .padding(.horizontal)
            }

            if !model.hints.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(model.hints) { hint in
                            Button { model.draft = hint.text } label: {
                                Text(hint.text)
                                    .font(.subheadline)
                                    .lineLimit(2)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: 220)
                                    .background(Brand.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 4)
            }

            HStack(spacing: 8) {
                Button { Task { await model.getHints() } } label: {
                    if model.loadingHints { ProgressView() } else { Image(systemName: "lightbulb") }
                }
                .disabled(model.unmatched)
                TextField(model.messages.isEmpty ? "Send your opener…" : "Text \(persona.name)…", text: $model.draft, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)
                    .disabled(model.unmatched)
                    .onSubmit { Task { await model.send() } }
                Button { Task { await model.send() } } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.title2)
                }
                .disabled(model.draft.trimmingCharacters(in: .whitespaces).isEmpty || model.waiting || model.unmatched)
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("New match") { model.endMatch() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await model.scoreChat() }
                } label: {
                    if model.scoring { ProgressView() } else { Text("Score me").bold() }
                }
                .disabled(!model.canScore)
            }
        }
    }
}

private struct InterestMeter: View {
    let value: Int

    private var color: Color {
        switch value {
        case ..<30: return .blue
        case ..<60: return .orange
        default: return Brand.accent
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Her interest").font(.caption.weight(.semibold))
                Spacer()
                Text("\(value)%").font(.caption.monospacedDigit())
            }
            ProgressView(value: Double(value), total: 100)
                .tint(color)
                .animation(.easeInOut, value: value)
        }
    }
}

private struct Bubble: View {
    let text: String
    let fromMe: Bool

    var body: some View {
        HStack {
            if fromMe { Spacer(minLength: 40) }
            Text(text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(fromMe ? Color.white : Color.primary)
                .background(fromMe ? Brand.accent : Color(uiColor: .secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 18))
            if !fromMe { Spacer(minLength: 40) }
        }
    }
}

private struct ScoreSheet: View {
    let score: PracticeScore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 6) {
                        Text("\(score.score)")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundStyle(Brand.accent)
                        Text(score.verdict)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                Section("Breakdown") {
                    ForEach(score.breakdown, id: \.label) { item in
                        HStack {
                            Text(item.label).frame(width: 100, alignment: .leading)
                            ProgressView(value: Double(max(0, min(10, item.value))), total: 10)
                                .tint(Brand.accent)
                            Text("\(item.value)/10").font(.caption.monospacedDigit()).frame(width: 44, alignment: .trailing)
                        }
                    }
                }
                Section("Fix this") {
                    ForEach(score.fixes, id: \.self) { fix in
                        Label(fix, systemImage: "wrench.adjustable")
                    }
                }
                if !score.better.isEmpty {
                    Section("Send this instead") {
                        ForEach(score.better, id: \.self) { line in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(line.instead_of).strikethrough().foregroundStyle(.secondary)
                                Text(line.try_this).fontWeight(.semibold)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("Your score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
