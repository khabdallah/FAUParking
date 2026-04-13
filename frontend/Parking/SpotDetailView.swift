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
        ZStack {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.14), Color.blue.opacity(0.08), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Spot \(spot.name)")
                            .font(.largeTitle)
                            .bold()

                        Text(spot.lotName)
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text("Category: \(spot.category.rawValue)")
                            .font(.subheadline)
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
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(statusColor.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: statusColor.opacity(0.16), radius: 10, x: 0, y: 5)

                    // Timing info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status Details")
                            .font(.headline)

                        HStack {
                            Image(systemName: "clock")
                            Text("Last updated")
                            Spacer()
                            Text(spot.lastUpdated, style: .time)
                                .font(.subheadline)
                        }
                        .foregroundStyle(.secondary)

                        HStack {
                            Image(systemName: "calendar")
                            Text("Date")
                            Spacer()
                            Text(spot.lastUpdated, style: .date)
                                .font(.subheadline)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.thinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                    )
                }
                .padding()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: spot.id)
        .navigationTitle("Spot \(spot.name)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SpotDetailView(
            spot: ParkingSpot(
                id: "1_1",
                name: "1_1",
                lotName: "lot_A",
                category: .white,
                status: .free,
                lastUpdated: Date()
            )
        )
    }
}
