import SwiftUI
import PhotosUI
import UIKit

@MainActor
final class ProfileReviewModel: ObservableObject {
    @Published var items: [PhotosPickerItem] = []
    @Published var photos: [Data] = []
    @Published var bio = ""
    @Published var loadingPhotos = false
    @Published var reviewing = false
    @Published var review: ProfileReview?
    @Published var error: String?

    static let maxPhotos = 6

    func loadPhotos() async {
        loadingPhotos = true
        defer { loadingPhotos = false }
        review = nil
        var loaded: [Data] = []
        for item in items.prefix(Self.maxPhotos) {
            if let data = try? await item.loadTransferable(type: Data.self),
               let jpeg = ImageTools.jpegForClaude(data: data) {
                loaded.append(jpeg)
            }
        }
        photos = loaded
    }

    func runReview() async {
        guard !photos.isEmpty, !reviewing else { return }
        reviewing = true
        error = nil
        defer { reviewing = false }
        do {
            review = try await ClaudeClient(store: .shared).reviewProfile(photosJPEG: photos, bio: bio)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func image(forPhoto number: Int) -> UIImage? {
        guard number >= 1, number <= photos.count else { return nil }
        return UIImage(data: photos[number - 1])
    }
}

struct ProfileReviewView: View {
    @StateObject private var model = ProfileReviewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $model.items,
                                 maxSelectionCount: ProfileReviewModel.maxPhotos,
                                 selectionBehavior: .ordered,
                                 matching: .images) {
                        Label(model.photos.isEmpty ? "Pick your profile photos, in order" : "Change photos",
                              systemImage: "person.crop.rectangle.stack")
                    }
                    if model.loadingPhotos {
                        ProgressView()
                    } else if !model.photos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(model.photos.enumerated()), id: \.offset) { index, _ in
                                    if let image = model.image(forPhoto: index + 1) {
                                        Thumbnail(image: image, number: index + 1)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Photos (up to \(ProfileReviewModel.maxPhotos))")
                } footer: {
                    Text("Tap them in the order they appear on your profile. Screenshots of your profile work too.")
                }

                Section("Bio") {
                    TextEditor(text: $model.bio).frame(minHeight: 70)
                }

                Section {
                    Button {
                        Task { await model.runReview() }
                    } label: {
                        HStack {
                            Text(model.reviewing ? "Reviewing…" : "Review my profile").fontWeight(.semibold)
                            Spacer()
                            if model.reviewing { ProgressView() }
                        }
                    }
                    .disabled(model.photos.isEmpty || model.reviewing)
                    if let error = model.error {
                        Text(error).font(.footnote).foregroundStyle(.red)
                    }
                } footer: {
                    Text("It judges what you control: light, setting, variety, vibe. It never rates looks.")
                }

                if let review = model.review {
                    Section("First impression") {
                        Text(review.first_impression)
                    }
                    Section("Photos") {
                        ForEach(review.photos.sorted { $0.photo < $1.photo }, id: \.self) { verdict in
                            HStack(alignment: .top, spacing: 12) {
                                if let image = model.image(forPhoto: verdict.photo) {
                                    Thumbnail(image: image, number: verdict.photo, size: 56)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(verdict.label)
                                        .font(.caption.weight(.heavy))
                                        .foregroundStyle(verdict.verdict == "replace" ? Color.red : Brand.accent)
                                    Text(verdict.why).font(.subheadline)
                                }
                            }
                        }
                    }
                    Section("Bio") {
                        Text(review.bio_feedback).foregroundStyle(.secondary)
                        Button {
                            UIPasteboard.general.string = review.bio_rewrite
                        } label: {
                            HStack(alignment: .top) {
                                Text(review.bio_rewrite).foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "doc.on.doc").foregroundStyle(.secondary)
                            }
                        }
                    }
                    Section("Next steps") {
                        ForEach(Array(review.next_steps.enumerated()), id: \.offset) { index, step in
                            Text("\(index + 1). \(step)")
                        }
                    }
                }
            }
            .navigationTitle("Profile Review")
            .onChange(of: model.items) { _, _ in
                Task { await model.loadPhotos() }
            }
        }
    }
}

private struct Thumbnail: View {
    let image: UIImage
    let number: Int
    var size: CGFloat = 72

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size * 1.33)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .topLeading) {
                Text("\(number)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(Brand.accent, in: Circle())
                    .padding(4)
            }
    }
}
