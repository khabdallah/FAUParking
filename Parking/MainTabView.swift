//
//  ContentView.swift
//  Parking
//
//  Created by Khalid Abdallah on 11/24/25.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var spotsViewModel = SpotsViewModel()

    var body: some View {
        TabView {
            DashboardView()
                .environmentObject(spotsViewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "dot.radiowaves.left.and.right")
                }

            SpotsListView()
                .environmentObject(spotsViewModel)
                .tabItem {
                    Label("Spots", systemImage: "parkingsign.circle")
                }

            NavigationStack {
                LotMapView()
                    .environmentObject(spotsViewModel)
            }
            .tabItem {
                Label("Map", systemImage: "map")
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
        .task {
            await spotsViewModel.load()
            spotsViewModel.startPeriodicRefresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                spotsViewModel.startPeriodicRefresh()
            case .background, .inactive:
                spotsViewModel.stopPeriodicRefresh()
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    MainTabView()
}
