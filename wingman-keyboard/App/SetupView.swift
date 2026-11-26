import SwiftUI
import UIKit

struct SetupView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("sk-ant-…", text: $model.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Link("Get a key at console.anthropic.com", destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                    Picker("Model", selection: $model.model) {
                        ForEach(SharedStore.modelChoices, id: \.id) { choice in
                            Text(choice.label).tag(choice.id)
                        }
                    }
                } header: {
                    Text("1 · Claude API key")
                } footer: {
                    Text("Stored on this phone only and shared with the Wingman keyboard. Each scan costs about 2–3¢ on Opus, much less on Haiku.")
                }

                Section {
                    StepText("Tap the button, then Keyboards.")
                    StepText("Turn on Wingman and Allow Full Access.")
                    StepText("Full Access lets the keyboard reach the internet and your screenshots. Without it, Scan can't work.")
                    Button("Open Wingman Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                } header: {
                    Text("2 · Turn on the keyboard")
                }

                Section {
                    HStack {
                        Text("Photos")
                        Spacer()
                        Text(model.photosStatusText).foregroundStyle(.secondary).multilineTextAlignment(.trailing)
                    }
                    if model.photosStatus == .notDetermined {
                        Button("Allow Photos") { model.requestPhotos() }
                    }
                } header: {
                    Text("3 · Let it find your screenshots")
                } footer: {
                    Text("Choose \"Allow Full Access\" so Scan can grab your newest screenshot. Wingman only ever reads the most recent screenshot, and only when you tap Scan.")
                }

                Section {
                    StepText("Open Shortcuts › + › add the action Take Screenshot.")
                    StepText("Add the action Get Wingman Replies. It uses the screenshot automatically.")
                    StepText("Name it \"Wingman\" and save.")
                    StepText("Settings › Accessibility › Touch › Back Tap › Double Tap › Wingman.")
                    StepText("Now, in any chat, double-tap the back of your phone. A few seconds later, tap the message box and your replies are waiting in the keyboard.")
                } header: {
                    Text("4 · Back Tap scan (optional, recommended)")
                }

                Section {
                    StepText("In the chat, take a screenshot (side + volume up). Or double-tap the back of your phone.")
                    StepText("Tap the message box. Hold 🌐 and pick Wingman.")
                    StepText("Tap Scan. Tap a reply to drop it in, then hit send.")
                    StepText("🔥 Lines has today's openers. The vibe button switches between Funny, Flirty, Get the #, and more.")
                } header: {
                    Text("How to use it")
                }
            }
            .navigationTitle("Setup")
            .onAppear { model.refresh() }
        }
    }
}

private struct StepText: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text).font(.subheadline)
    }
}
