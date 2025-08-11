//
//  TrainsApp.swift
//  Trains
//
//  Created by Diana Viter on 07.07.2025.
//

import SwiftUI

@main
struct TrainsApp: App {
    @StateObject private var errorManager = ErrorManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(errorManager)
                .fullScreenCover(item: $errorManager.presentedError,
                                 onDismiss: { errorManager.dismiss() }) { err in
                    ErrorScreen(type: err.type)
                }
        }
    }
}

