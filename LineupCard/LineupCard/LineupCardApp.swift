import SwiftUI

@main
struct LineupCardApp: App {
    @StateObject private var store = CardStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
