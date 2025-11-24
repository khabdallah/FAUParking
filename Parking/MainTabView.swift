//
//  ContentView.swift
//  Parking
//
//  Created by Khalid Abdallah on 11/24/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "dot.radiowaves.left.and.right")
                }

            SpotsListView(spots: MockData.spots)
                .tabItem {
                    Label("Spots", systemImage: "parkingsign.circle")
                }

            DronesListView(drones: MockData.drones)
                .tabItem {
                    Label("Drones", systemImage: "airplane.circle")
                }

            AlertsListView(alerts: MockData.alerts)
                .tabItem {
                    Label("Alerts", systemImage: "exclamationmark.triangle")
                }
        }
    }
}

#Preview {
    MainTabView()
}
