//
//  MainAppView.swift
//  Trains
//
//  Created by Diana Viter on 03.08.2025.
//

import SwiftUI

struct MainAppView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "trainsWhite") ?? .white
        
        appearance.shadowColor = .trainsGray
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        UITabBar.appearance().tintColor = UIColor(Color.trainsBlack)
    }
    
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image("Schedule tab")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 30, height: 30)
                }
            
            SettingsView()
                .tabItem {
                    Image("Tab Gear")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 30, height: 30)
                }
        }
        .accentColor(.trainsBlack)
    }
}

#Preview {
    MainAppView()
}
