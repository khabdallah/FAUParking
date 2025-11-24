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
                                .font(.caption)
                        }
                        .progressViewStyle(.linear)
                        .frame(width: 90)
                    }
                }
            }
            .navigationTitle("Drones")
        }
    }
}

#Preview {
    DronesListView(drones: MockData.drones)
}

