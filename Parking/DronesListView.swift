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
                                .font(.caption2)
                        }
                        .progressViewStyle(.linear)
                        .frame(width: 90)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: drone.batteryLevel)
            }
            .animation(.easeInOut(duration: 0.25), value: drones.count)
            .navigationTitle("Drones")
        }
    }
}

#Preview {
    DronesListView(drones: MockData.drones)
}
