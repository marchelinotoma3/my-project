import SwiftUI

@main
struct WingmanApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .tint(Brand.accent)
        }
    }
}

enum Brand {
    static let accent = Color(red: 1.0, green: 0.29, blue: 0.36)
}

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    @State private var tab: AppTab = .today

    enum AppTab { case today, coach, playbook, setup }

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .tabItem { Label("Lines", systemImage: "flame.fill") }
                .tag(AppTab.today)
            CoachView()
                .tabItem { Label("Coach", systemImage: "bubble.left.and.text.bubble.right.fill") }
                .tag(AppTab.coach)
            PlaybookView()
                .tabItem { Label("Playbook", systemImage: "book.fill") }
                .tag(AppTab.playbook)
            SetupView()
                .tabItem { Label("Setup", systemImage: "gearshape.fill") }
                .tag(AppTab.setup)
        }
        .onAppear {
            if model.apiKey.isEmpty { tab = .setup }
        }
    }
}
