import SwiftUI

struct PlaybookView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("\"Girls don't want you to be normal.\" Be unexpected, stay unbothered, and close fast. This is the method from @stockton.mcclellan's reels, and the keyboard's AI follows it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section("The method") {
                    ForEach(Playbook.principles) { principle in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(principle.emoji) \(principle.title)").font(.headline)
                            Text(principle.body).font(.subheadline)
                            Text(principle.example)
                                .font(.footnote.italic())
                                .foregroundStyle(Brand.accent)
                        }
                        .padding(.vertical, 4)
                    }
                }
                Section("The 5-step chat") {
                    StepRow(number: 1, title: "Weird setup", detail: "A strange line that makes her ask \"wym?\"")
                    StepRow(number: 2, title: "Pun payoff", detail: "Land the double meaning on her follow-up.")
                    StepRow(number: 3, title: "Run the bit", detail: "Stay in the theme. Build on what she adds.")
                    StepRow(number: 4, title: "Match, then raise", detail: "One notch at a time, only after she matches.")
                    StepRow(number: 5, title: "Close", detail: "\"phone number\" on her warmest message.")
                }
                Section("Profile") {
                    Text("Lead with your best photo: a real smile, good light, some energy.")
                    Text("Cut bathroom-mirror and parking-garage selfies.")
                    Text("No duplicates. Every photo should show a different setting or outfit.")
                }
            }
            .navigationTitle("Playbook")
        }
    }
}

private struct StepRow: View {
    let number: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Brand.accent, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
