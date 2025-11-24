//
//  Models.swift
//  Parking
//
//  Created by Khalid Abdallah on 11/24/25.
//

import Foundation
import CoreLocation

enum SpotStatus: String, CaseIterable {
    case free = "Free"
    case occupied = "Occupied"
    case uncertain = "Uncertain"
    case occluded = "Occluded"
}

struct ParkingSpot: Identifiable {
    let id: UUID = UUID()
    let name: String          // e.g. "Spot A12"
    let zone: String          // e.g. "Zone A"
    let status: SpotStatus
    let lastUpdated: Date
}

enum DroneStatus: String {
    case idle = "Idle"
    case patrolling = "Patrolling"
    case rth = "Return to Home"
    case offline = "Offline"
}

struct Drone: Identifiable {
    let id: UUID = UUID()
    let name: String          // e.g. "Drone 1"
    let batteryLevel: Double  // 0.0 – 1.0
    let status: DroneStatus
    let zone: String
}

struct AlertItem: Identifiable {
    let id: UUID = UUID()
    let title: String
    let message: String
    let timestamp: Date
    let severity: String      // e.g. "Info", "Warning", "Critical"
}

// MARK: - Mock Data

struct MockData {
    static let spots: [ParkingSpot] = [
        ParkingSpot(name: "A01", zone: "Zone A", status: .free,      lastUpdated: Date()),
        ParkingSpot(name: "A02", zone: "Zone A", status: .occupied,  lastUpdated: Date().addingTimeInterval(-120)),
        ParkingSpot(name: "B15", zone: "Zone B", status: .uncertain, lastUpdated: Date().addingTimeInterval(-300)),
        ParkingSpot(name: "C07", zone: "Zone C", status: .free,      lastUpdated: Date().addingTimeInterval(-30)),
        ParkingSpot(name: "D22", zone: "Zone D", status: .occluded,  lastUpdated: Date().addingTimeInterval(-600))
    ]

    static let drones: [Drone] = [
        Drone(name: "Drone 1", batteryLevel: 0.82, status: .patrolling, zone: "Zone A"),
        Drone(name: "Drone 2", batteryLevel: 0.45, status: .rth,        zone: "Zone B"),
        Drone(name: "Drone 3", batteryLevel: 0.93, status: .idle,       zone: "Hangar"),
        Drone(name: "Drone 4", batteryLevel: 0.18, status: .patrolling, zone: "Zone C")
    ]

    static let alerts: [AlertItem] = [
        AlertItem(
            title: "Battery Low",
            message: "Drone 4 battery below 20%. Returning to home.",
            timestamp: Date().addingTimeInterval(-60),
            severity: "Warning"
        ),
        AlertItem(
            title: "Spot A02 change",
            message: "Spot A02 changed from Free to Occupied.",
            timestamp: Date().addingTimeInterval(-300),
            severity: "Info"
        ),
        AlertItem(
            title: "Occlusion detected",
            message: "Zone D camera view partially blocked. Confidence reduced.",
            timestamp: Date().addingTimeInterval(-900),
            severity: "Info"
        )
    ]
}
