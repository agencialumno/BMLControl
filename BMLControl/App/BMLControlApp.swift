import SwiftUI

@main
struct BMLControlApp: App {
    @StateObject private var bleManager = BLEManager()

    var body: some Scene {
        WindowGroup {
            BLEProofOfConceptView(bleManager: bleManager)
        }
    }
}