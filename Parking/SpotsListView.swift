//
//  SpotsListView.swift
//  Parking
//
//  Created by Khalid Abdallah on 11/24/25.
//

import SwiftUI

struct SpotsListView: View {
    let spots: [ParkingSpot]

    var body: some View {
        NavigationStack {
            List(spots) { spot in
                NavigationLink {
                    SpotDetailView(spot: spot)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Spot \(spot.name)")
                                .font(.headline)
                            Text(spot.zone)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("Last updated \(spot.lastUpdated, style: .time)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(spot.status.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor(spot.status).opacity(0.15))
                            .foregroundColor(statusColor(spot.status))
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Parking Spots")
        }
    }

    private func statusColor(_ status: SpotStatus) -> Color {
        switch status {
        case .free: return .green
        case .occupied: return .red
        case .uncertain: return .orange
        case .occluded: return .gray
        }
    }
}

#Preview {
    SpotsListView(spots: MockData.spots)
}

