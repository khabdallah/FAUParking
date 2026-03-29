//
//  DronesListView.swift
//  Parking
//
//  Created by Khalid Abdallah on 11/24/25.
//

import SwiftUI

struct DronesListView: View {
    let drones: [Drone]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.14), Color.blue.opacity(0.08), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                List(drones) { drone in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(drone.name)
                                .font(.headline)
                            Text(drone.zone)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(drone.status.rawValue)
                                .font(.subheadline)

                            ProgressView(value: drone.batteryLevel) {
                                Text("Battery")
                                    .font(.caption2)
                            }
                            .progressViewStyle(.linear)
                            .tint(.accentColor)
                            .frame(width: 90)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor.opacity(0.14), lineWidth: 1)
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .animation(.easeInOut(duration: 0.2), value: drone.batteryLevel)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .animation(.easeInOut(duration: 0.25), value: drones.count)
            .navigationTitle("Drones")
        }
    }
}

#Preview {
    DronesListView(drones: MockData.drones)
}
