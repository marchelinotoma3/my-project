import SwiftUI
import UIKit

struct TodayView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Spice", selection: $model.spice) {
                        ForEach(Spice.allCases) { spice in
                            Text("\(spice.emoji) \(spice.title)").tag(spice)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    ForEach(model.todayLines) { line in
                        LineCard(line: line)
                    }
                } header: {
                    Text(Date.now.formatted(date: .complete, time: .omitted))
                } footer: {
                    Text("Same five all day. New ones tomorrow. They're in the keyboard too: tap 🔥 Lines.")
                }

                if !model.freshLines.isEmpty {
                    Section("Fresh from AI") {
                        ForEach(model.freshLines) { line in
                            LineCard(line: line)
                        }
                    }
                }

                Section {
                    Button {
                        Task { await model.writeFreshLines() }
                    } label: {
                        HStack {
                            Label(model.loadingLines ? "Writing…" : "Write me 5 fresh lines", systemImage: "sparkles")
                            if model.loadingLines {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(model.loadingLines)
                    if let error = model.linesError {
                        Text(error).font(.footnote).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Lines of the Day")
            .onAppear { model.refresh() }
        }
    }
}

struct LineCard: View {
    let line: DailyLine
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(line.kindTitle.uppercased()) \(line.spice.emoji)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Brand.accent)
                Spacer()
                Button {
                    UIPasteboard.general.string = line.setup
                    copied = true
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.borderless)
            }
            Text(line.setup).font(.headline)
            Text("her: \(line.herReply)").font(.subheadline).foregroundStyle(.secondary)
            Text("you: \(line.payoff)").font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}
