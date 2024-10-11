//  QLMIDIApp
//
//  This is the app that contains the Quick Look extension. It's just a placeholder for now, but in the
//  future it will be expanded into a preferences panel.

import SwiftUI

@main
struct QLMIDIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
            .frame(
                minWidth: 300, maxWidth: 300,
                minHeight: 400, maxHeight: 400)
        }
        .windowResizability(.contentSize)
    }
}
