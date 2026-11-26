import SwiftUI
import PhotosUI
import UIKit

/// In-app version of Scan: pick a screenshot or paste the chat.
struct CoachView: View {
    @EnvironmentObject var model: AppModel
    @State private var pickedItem: PhotosPickerItem?
    @State private var pickedImage: Data?
    @State private var chatText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $pickedItem, matching: .screenshots) {
                        Label(pickedImage == nil ? "Pick a chat screenshot" : "Screenshot picked ✅",
                              systemImage: "photo.on.rectangle")
                    }
                    if let pickedImage, let image = UIImage(data: pickedImage) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    ZStack(alignment: .topLeading) {
                        if chatText.isEmpty {
                            Text("…or paste the messages here")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $chatText)
                            .frame(minHeight: 90)
                    }
                } header: {
                    Text("The chat")
                }

                Section {
                    Picker("Vibe", selection: $model.vibe) {
                        ForEach(Vibe.allCases) { vibe in
                            Text("\(vibe.emoji) \(vibe.title)").tag(vibe)
                        }
                    }
                    Picker("Spice", selection: $model.spice) {
                        ForEach(Spice.allCases) { spice in
                            Text("\(spice.emoji) \(spice.title)").tag(spice)
                        }
                    }
                    Button {
                        Task { await model.coach(imageData: pickedImage, chatText: chatText) }
                    } label: {
                        HStack {
                            Text(model.coaching ? "Checking the vibe…" : "What do I text?")
                                .fontWeight(.semibold)
                            Spacer()
                            if model.coaching { ProgressView() }
                        }
                    }
                    .disabled(model.coaching || (pickedImage == nil && chatText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                    if let error = model.coachError {
                        Text(error).font(.footnote).foregroundStyle(.red)
                    }
                }

                if let result = model.coachResult ?? model.latestScan {
                    AnalysisSection(analysis: result)
                }
            }
            .navigationTitle("Coach")
            .onChange(of: pickedItem) { _, item in
                Task {
                    pickedImage = try? await item?.loadTransferable(type: Data.self)
                }
            }
            .onAppear { model.refresh() }
        }
    }
}

struct AnalysisSection: View {
    let analysis: Analysis

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(analysis.interestEmoji) \(analysis.read)").font(.headline)
                Text(analysis.move).font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            ForEach(analysis.replies) { reply in
                ReplyRow(reply: reply)
            }
        } header: {
            if let created = analysis.createdAt {
                Text("Send this · \(created.formatted(date: .omitted, time: .shortened))\(analysis.source.map { " · \($0)" } ?? "")")
            } else {
                Text("Send this")
            }
        }
    }
}

struct ReplyRow: View {
    let reply: Reply
    @State private var copied = false

    var body: some View {
        Button {
            UIPasteboard.general.string = reply.text
            copied = true
        } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(reply.text).font(.body.weight(.medium)).foregroundStyle(.primary)
                    Text("\(reply.style.uppercased()) · \(reply.why)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.accent)
                }
                Spacer()
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
