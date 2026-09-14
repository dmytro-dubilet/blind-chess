import SwiftUI

@main
struct BlindChessApp: App {
    @StateObject private var model = GameModel()
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup {
            GameView(model: model)
                .environment(\.locale, Locale(identifier: model.language.rawValue))
                .preferredColorScheme(.dark)
                .onAppear { model.resume() }
                .onChange(of: phase) { _, value in
                    if value == .background { model.suspend() }
                    else if value == .active { model.resume() }
                }
        }
    }
}
