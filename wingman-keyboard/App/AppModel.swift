import SwiftUI
import Photos

/// App-side state. Everything the keyboard needs is written through to SharedStore.
@MainActor
final class AppModel: ObservableObject {
    private let store = SharedStore.shared

    @Published var apiKey: String { didSet { store.apiKey = apiKey } }
    @Published var model: String { didSet { store.model = model } }
    @Published var spice: Spice { didSet { store.spice = spice; reloadLines() } }
    @Published var vibe: Vibe { didSet { store.vibe = vibe } }

    @Published var todayLines: [DailyLine] = []
    @Published var freshLines: [DailyLine] = []
    @Published var loadingLines = false
    @Published var linesError: String?

    @Published var coaching = false
    @Published var coachResult: Analysis?
    @Published var coachError: String?
    @Published var latestScan: Analysis?

    @Published var photosStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    init() {
        let shared = SharedStore.shared
        apiKey = shared.apiKey
        model = shared.model
        spice = shared.spice
        vibe = shared.vibe
        latestScan = shared.latestAnalysis
        reloadLines()
    }

    func refresh() {
        latestScan = store.latestAnalysis
        photosStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        reloadLines()
    }

    // MARK: Lines of the day

    func reloadLines() {
        todayLines = LinesOfTheDay.today(spice: spice)
        freshLines = store.freshLines(for: LinesOfTheDay.dayNumber()) ?? []
    }

    func writeFreshLines() async {
        loadingLines = true
        linesError = nil
        defer { loadingLines = false }
        do {
            let lines = try await ClaudeClient(store: store).freshLines(spice: spice)
            store.saveFreshLines(lines, for: LinesOfTheDay.dayNumber())
            freshLines = lines
        } catch {
            linesError = error.localizedDescription
        }
    }

    // MARK: Coach

    func coach(imageData: Data?, chatText: String) async {
        coaching = true
        coachError = nil
        defer { coaching = false }
        let jpeg = imageData.flatMap { ImageTools.jpegForClaude(data: $0) }
        if imageData != nil && jpeg == nil {
            coachError = "Couldn't read that image."
            return
        }
        do {
            var result = try await ClaudeClient(store: store).suggestReplies(
                imageJPEG: jpeg, chatText: chatText, draft: nil, vibe: vibe, spice: spice)
            result.source = jpeg != nil ? "app screenshot" : "app text"
            coachResult = result
            store.latestAnalysis = result
            latestScan = result
        } catch {
            coachError = error.localizedDescription
        }
    }

    // MARK: Photos

    func requestPhotos() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            Task { @MainActor in self.photosStatus = status }
        }
    }

    var photosStatusText: String {
        switch photosStatus {
        case .authorized: return "Allowed ✅"
        case .limited: return "Limited. Screenshots you didn't select won't be found."
        case .denied, .restricted: return "Blocked. Turn it on in Settings › Wingman › Photos."
        case .notDetermined: return "Not asked yet"
        @unknown default: return "Unknown"
        }
    }
}
