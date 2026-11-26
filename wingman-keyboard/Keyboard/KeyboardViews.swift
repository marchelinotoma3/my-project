import SwiftUI
import UIKit

/// Layout constants and colors for the keyboard.
enum KB {
    static let toolbarHeight: CGFloat = 46
    static let stripHeight: CGFloat = 58
    static let keysHeight: CGFloat = 224
    static var totalHeight: CGFloat { toolbarHeight + stripHeight + keysHeight }

    static let accent = Color(red: 1.0, green: 0.29, blue: 0.36)
    static let background = dynamic(light: UIColor(red: 0.82, green: 0.83, blue: 0.86, alpha: 1),
                                     dark: UIColor(white: 0.14, alpha: 1))
    static let key = dynamic(light: .white, dark: UIColor(white: 0.40, alpha: 1))
    static let specialKey = dynamic(light: UIColor(red: 0.67, green: 0.69, blue: 0.73, alpha: 1),
                                    dark: UIColor(white: 0.26, alpha: 1))
    static let card = dynamic(light: UIColor(white: 1, alpha: 0.95), dark: UIColor(white: 0.24, alpha: 1))

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

struct KeyboardRootView: View {
    @ObservedObject var state: KeyboardState

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(state: state)
            switch state.panel {
            case .keys:
                StripView(state: state)
                KeysView(state: state)
            case .replies:
                RepliesPanel(state: state)
            case .lines:
                LinesPanel(state: state)
            case .vibes:
                VibePanel(state: state)
            }
        }
        .frame(height: KB.totalHeight)
        .frame(maxWidth: .infinity)
        .background(KB.background)
    }
}

// MARK: - Toolbar

struct Pill: View {
    let label: String
    var icon: String? = nil
    var emoji: String? = nil
    var prominent = false
    var selected = false
    var glowing = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon { Image(systemName: icon).font(.system(size: 13, weight: .bold)) }
                if let emoji { Text(emoji).font(.system(size: 13)) }
                Text(label).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                if glowing { Circle().fill(Color.white).frame(width: 6, height: 6) }
            }
            .padding(.horizontal, 11)
            .frame(height: 32)
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .background(prominent ? KB.accent : (selected ? KB.accent.opacity(0.28) : KB.key), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ToolbarView: View {
    @ObservedObject var state: KeyboardState

    var body: some View {
        HStack(spacing: 7) {
            Text("W")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
                .frame(width: 30, height: 30)
                .background(KB.accent, in: RoundedRectangle(cornerRadius: 8))

            Pill(label: "Scan", icon: "viewfinder", prominent: true, glowing: state.screenshotReady) {
                state.scan()
            }
            Pill(label: "Lines", icon: "flame.fill", selected: state.panel == .lines) {
                state.toggle(.lines)
            }
            Pill(label: state.vibe.title, emoji: state.vibe.emoji, selected: state.panel == .vibes) {
                state.toggle(.vibes)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(height: KB.toolbarHeight)
    }
}

// MARK: - Status / suggestion strip

struct StatusLine: View {
    let status: KeyboardState.Status

    var body: some View {
        switch status {
        case .working(let message):
            HStack(spacing: 8) {
                ProgressView()
                Text(message).font(.system(size: 14, weight: .medium))
            }
        case .error(let message):
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(KB.accent)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        case .hint(let message):
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        case .idle:
            EmptyView()
        }
    }
}

struct StripView: View {
    @ObservedObject var state: KeyboardState

    private var isBusyOrError: Bool {
        switch state.status {
        case .working, .error: return true
        default: return false
        }
    }

    var body: some View {
        Group {
            if let analysis = state.analysis, !isBusyOrError {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        Button { state.panel = .replies } label: {
                            Text(analysis.interestEmoji)
                                .font(.system(size: 20))
                                .frame(width: 40, height: 44)
                                .background(KB.card, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        ForEach(analysis.replies) { reply in
                            Button { state.insert(reply.text) } label: {
                                Text(reply.text)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal, 10)
                                    .frame(maxWidth: 230, minHeight: 44)
                                    .background(KB.card, in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            } else {
                StatusLine(status: state.status)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: KB.stripHeight)
    }
}

// MARK: - Keys

struct KeyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.5 : 1)
    }
}

struct KeyCap: View {
    var label: String = ""
    var systemImage: String? = nil
    var special = false
    var width: CGFloat? = nil
    var fontSize: CGFloat = 22
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            KeyFace(label: label, systemImage: systemImage, special: special, width: width, fontSize: fontSize)
        }
        .buttonStyle(KeyPressStyle())
    }
}

struct KeyFace: View {
    var label: String = ""
    var systemImage: String? = nil
    var special = false
    var width: CGFloat? = nil
    var fontSize: CGFloat = 22

    var body: some View {
        ZStack {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 18, weight: .regular))
            } else {
                Text(label).font(.system(size: fontSize))
            }
        }
        .frame(width: width, height: 44)
        .frame(maxWidth: width == nil ? CGFloat.infinity : nil)
        .foregroundStyle(Color.primary)
        .background(special ? KB.specialKey : KB.key, in: RoundedRectangle(cornerRadius: 6))
        .shadow(color: Color.black.opacity(0.28), radius: 0, x: 0, y: 1)
        .contentShape(Rectangle())
    }
}

struct KeysView: View {
    @ObservedObject var state: KeyboardState

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 6
            let keyWidth = (geo.size.width - 6 - spacing * 9) / 10
            let rows = state.letterRows

            VStack(spacing: 11) {
                characterRow(rows[0], keyWidth: keyWidth, spacing: spacing)
                characterRow(rows[1], keyWidth: keyWidth, spacing: spacing)

                HStack(spacing: spacing) {
                    leftModifierKey(width: keyWidth * 1.3)
                    Spacer(minLength: 0)
                    characterRow(rows[2], keyWidth: state.keySet == .letters ? keyWidth : keyWidth * 1.35, spacing: spacing)
                    Spacer(minLength: 0)
                    KeyFace(systemImage: "delete.left", special: true, width: keyWidth * 1.3)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in state.deletePressed() }
                                .onEnded { _ in state.deleteReleased() }
                        )
                }

                HStack(spacing: spacing) {
                    KeyCap(label: state.keySet == .letters ? "123" : "ABC", special: true,
                           width: keyWidth * 1.25, fontSize: 16) {
                        state.toggleNumbers()
                    }
                    if state.needsGlobeKey {
                        KeyCap(systemImage: "globe", special: true, width: keyWidth * 1.1) {
                            state.nextKeyboard()
                        }
                    }
                    KeyCap(label: "space", fontSize: 16) { state.space() }
                    KeyCap(label: "return", special: true, width: keyWidth * 2.2, fontSize: 16) {
                        state.newline()
                    }
                }
            }
            .padding(.horizontal, 3)
            .padding(.top, 6)
        }
        .frame(height: KB.keysHeight)
    }

    private func characterRow(_ keys: [String], keyWidth: CGFloat, spacing: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                KeyCap(label: state.display(key), width: keyWidth) { state.type(key) }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func leftModifierKey(width: CGFloat) -> some View {
        switch state.keySet {
        case .letters:
            let icon: String = {
                switch state.shift {
                case .off: return "shift"
                case .once: return "shift.fill"
                case .locked: return "capslock.fill"
                }
            }()
            KeyCap(systemImage: icon, special: state.shift == .off, width: width) { state.tapShift() }
        case .numbers:
            KeyCap(label: "#+=", special: true, width: width, fontSize: 16) { state.toggleSymbols() }
        case .symbols:
            KeyCap(label: "123", special: true, width: width, fontSize: 16) { state.toggleSymbols() }
        }
    }
}

// MARK: - Panels

struct PanelFooter<Leading: View>: View {
    @ObservedObject var state: KeyboardState
    @ViewBuilder var leading: () -> Leading

    var body: some View {
        HStack {
            leading()
            Spacer()
            Pill(label: "ABC", icon: "keyboard") { state.panel = .keys }
        }
        .padding(.horizontal, 8)
        .frame(height: 44)
    }
}

struct RepliesPanel: View {
    @ObservedObject var state: KeyboardState

    var body: some View {
        VStack(spacing: 0) {
            if state.status != .idle {
                StatusLine(status: state.status).padding(.horizontal, 12).padding(.vertical, 4)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 7) {
                    if let analysis = state.analysis {
                        HStack(alignment: .top, spacing: 8) {
                            Text(analysis.interestEmoji).font(.system(size: 22))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(analysis.read).font(.system(size: 14, weight: .semibold))
                                Text(analysis.move).font(.system(size: 12)).foregroundStyle(.secondary)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(KB.card.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))

                        ForEach(analysis.replies) { reply in
                            Button { state.insert(reply.text) } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(reply.text)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Color.primary)
                                        .multilineTextAlignment(.leading)
                                    Text("\(reply.style.uppercased()) · \(reply.why)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(KB.accent)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(KB.card, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Text("No scan yet. Screenshot the chat, then tap Scan.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 30)
                    }
                }
                .padding(.horizontal, 8)
            }
            PanelFooter(state: state) {
                Pill(label: "Again", icon: "arrow.clockwise") { state.scan() }
            }
        }
        .frame(height: KB.stripHeight + KB.keysHeight)
    }
}

struct LinesPanel: View {
    @ObservedObject var state: KeyboardState

    var body: some View {
        VStack(spacing: 0) {
            if case .error = state.status {
                StatusLine(status: state.status).padding(.horizontal, 12).padding(.vertical, 4)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(state.lines) { line in
                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(line.kindTitle.uppercased()) \(line.spice.emoji)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(KB.accent)
                            Button { state.insert(line.setup) } label: {
                                Text(line.setup)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            Text("her: \(line.herReply)")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Button { state.insert(line.payoff) } label: {
                                Text("then: \(line.payoff)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.primary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(KB.card, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 8)
            }
            PanelFooter(state: state) {
                Pill(label: state.loadingFreshLines ? "Writing…" : "Fresh lines", icon: "sparkles") {
                    state.writeFreshLines()
                }
            }
        }
        .frame(height: KB.stripHeight + KB.keysHeight)
    }
}

struct VibePanel: View {
    @ObservedObject var state: KeyboardState
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT DO YOU WANT?")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Vibe.allCases) { vibe in
                    Pill(label: vibe.title, emoji: vibe.emoji, selected: state.vibe == vibe) {
                        state.setVibe(vibe)
                    }
                }
            }
            Text("SPICE")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(Spice.allCases) { spice in
                    Pill(label: spice.title, emoji: spice.emoji, selected: state.spice == spice) {
                        state.setSpice(spice)
                    }
                }
            }
            Spacer(minLength: 0)
            HStack {
                Text("Your pick is used on the next Scan.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                Pill(label: "Scan now", icon: "viewfinder", prominent: true) { state.scan() }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: KB.stripHeight + KB.keysHeight)
    }
}
