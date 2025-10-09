//
//  ContentView.swift
//  Pyosition
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedTab = 0
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }
                .tag(0)
            
            PlanView()
                .tabItem {
                    Label("계획", systemImage: "star")
                }
                .tag(1)
            
            StatsView()
                .tabItem {
                    Label("통계", systemImage: "chart.bar")
                }
                .tag(2)
            
            MoreView()
                .tabItem {
                    Label("더보기", systemImage: "ellipsis")
                }
                .tag(3)
        }
        .tint(.green)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
    }
}

