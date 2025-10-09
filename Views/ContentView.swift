//
//  ContentView.swift
//  Trains
//
//  Created by Diana Viter on 07.07.2025.
//

import SwiftUI
import OpenAPIURLSession

struct ContentView: View {
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            Image(.splashScreen)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        }
        .task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            isActive = true
        }
        .fullScreenCover(isPresented: $isActive) {
            MainAppView()
        }
    }
}

#Preview {
    ContentView()
}
