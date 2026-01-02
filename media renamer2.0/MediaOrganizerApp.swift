//
//  MediaOrganizerApp.swift
//  Regia
//
//  Entry Point: Gestisce il ciclo di vita dell'app e la Barra dei Menu
//

import SwiftUI

@main
struct RegiaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Impostazioni...") {
                    NotificationCenter.default.post(name: Notification.Name("OpenSettings"), object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
