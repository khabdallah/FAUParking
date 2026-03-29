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
        ZStack(alignment: .top) {
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
            }
            .tint(.accentColor)

            if spotsViewModel.isShowingCachedData {
                HStack(spacing: 8) {
                    Image(systemName: "icloud.slash.fill")
                        .foregroundStyle(.orange)
                    Text(offlineBannerText)
                        .font(.caption.weight(.semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                )
                .padding(.top, 8)
                .padding(.horizontal, 12)
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

    private var offlineBannerText: String {
        if let cacheTimestamp = spotsViewModel.cacheTimestamp {
            return "Offline mode: showing cached data from \(cacheTimestamp.formatted(date: .omitted, time: .shortened))."
        }
        return "Offline mode: showing cached data."
    }
}

#Preview {
    MainTabView()
}
