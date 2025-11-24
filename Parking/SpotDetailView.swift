//
//  SpotDetailView.swift
//  Parking
//
//  Created by Khalid Abdallah on 11/24/25.
//

import SwiftUI

struct SpotDetailView: View {
    let spot: ParkingSpot

    private var statusColor: Color {
        switch spot.status {
        case .free: return .green
        case .occupied: return .red
        case .uncertain: return .orange
        case .occluded: return .gray
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Header card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Spot \(spot.name)")
                        .font(.largeTitle)
                        .bold()

                    Text(spot.zone)
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 10, height: 10)

                        Text(spot.status.rawValue)
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.12))
                            .cornerRadius(10)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial)
                .cornerRadius(16)

                // Timeline / metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text("Status Details")
                        .font(.headline)

                    HStack {
                        Image(systemName: "clock")
                        Text("Last updated:")
                        Spacer()
                        Text(spot.lastUpdated, style: .time)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)

                    HStack {
                        Image(systemName: "calendar")
                        Text("Date:")
                        Spacer()
                        Text(spot.lastUpdated, style: .date)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)

                // Placeholder for future extensions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Analytics (Future)")
                        .font(.headline)

                    Text("Here you can later show:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Occupancy duration")
                        Text("• Confidence score from the model")
                        Text("• Historical status timeline")
                        Text("• Linked drone passes over this spot")
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Spot \(spot.name)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SpotDetailView(spot: MockData.spots.first!)
    }
}
