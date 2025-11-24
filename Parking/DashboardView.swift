//
//  DashboardView.swift
//  Parking
//
//  Created by Khalid Abdallah on 11/24/25.
//

import Foundation
import SwiftUI

struct DashboardView: View {
    // In a real app these would be @StateObject view models
    let spots = MockData.spots
    let drones = MockData.drones
    let alerts = MockData.alerts

    var freeSpotsCount: Int {
        spots.filter { $0.status == .free }.count
    }

    var occupiedSpotsCount: Int {
        spots.filter { $0.status == .occupied }.count
    }

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

                    // Quick stats
                    HStack(spacing: 12) {
                        StatCard(title: "Free Spots",
                                 value: "\(freeSpotsCount)",
                                 systemImage: "checkmark.circle")

                        StatCard(title: "Occupied",
                                 value: "\(occupiedSpotsCount)",
                                 systemImage: "xmark.circle")

                        StatCard(title: "Active Drones",
                                 value: "\(drones.filter { $0.status == .patrolling }.count)",
                                 systemImage: "airplane.circle.fill")
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
                }
                .padding(.vertical, 8)
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
}
