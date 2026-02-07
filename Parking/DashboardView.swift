//
//  DashboardView.swift
//  Parking
//
//  Created by Khalid Abdallah on 11/24/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var spotsViewModel: SpotsViewModel

    private let drones = MockData.drones
    private let alerts = MockData.alerts

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Map placeholder
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .frame(height: 220)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "map")
                                    .font(.system(size: 40))
                                Text("Live Map View")
                                    .font(.headline)
                                Text("Drone coverage and parking zones")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)

                    // Stats
                    HStack(spacing: 12) {
                        StatCard(
                            title: "Free Spots",
                            value: "\(spotsViewModel.freeSpotsCount)",
                            systemImage: "checkmark.circle"
                        )

                        StatCard(
                            title: "Occupied",
                            value: "\(spotsViewModel.occupiedSpotsCount)",
                            systemImage: "xmark.circle"
                        )

                        StatCard(
                            title: "Active Drones",
                            value: "\(drones.filter { $0.status == .patrolling }.count)",
                            systemImage: "airplane.circle.fill"
                        )
                    }
                    .padding(.horizontal)

                    // Recent alerts
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recent Alerts")
                                .font(.headline)
                            Spacer()
                            Text("\(alerts.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        ForEach(alerts.prefix(3)) { alert in
                            AlertRow(alert: alert)
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    if spotsViewModel.isLoading {
                        ProgressView("Refreshing data…")
                            .padding(.top, 8)
                    }

                    if let error = spotsViewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 8)
            }
            .refreshable {
                await spotsViewModel.load()
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
            Text(value)
                .font(.title2)
                .bold()
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .cornerRadius(14)
    }
}

#Preview {
    DashboardView()
        .environmentObject(SpotsViewModel())
}
