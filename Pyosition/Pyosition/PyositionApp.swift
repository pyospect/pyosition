//
//  PyositionApp.swift
//  Pyosition
//

import SwiftUI

@main
struct PyositionApp: App {
    @StateObject private var dataStore = DataStore.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
        }
    }
}

