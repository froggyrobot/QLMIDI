//
//  QLMIDIApp.swift
//  QLMIDI
//
//  Created by froggyrobot on 7/30/24.
//

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
//        .defaultSize(width: 900, height: 900)
        .windowResizability(.contentSize)
    }
}
