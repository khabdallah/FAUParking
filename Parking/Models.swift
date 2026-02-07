//
//  Models.swift
//  Parking
//
//  Created by Khalid Abdallah on 11/24/25.
//

import Foundation

// MARK: - Backend models

struct Lot: Identifiable, Codable {
    let id: String        // maps from lot_id
    let name: String      // maps from lot_name

    enum CodingKeys: String, CodingKey {
        case id = "lot_id"
        case name = "lot_name"
    }
}

enum SpaceCategory: String, Codable {
    case white
    case blue
    case green
    // add more if needed
}

struct Space: Identifiable, Codable {
    let id: String            // e.g. "1_1"
    let lotId: String         // maps from lot_id
    let category: SpaceCategory
    let status: Int           // 1 or 0 from DB

    enum CodingKeys: String, CodingKey {
        case id
        case lotId = "lot_id"
        case category
        case status
    }
}

// MARK: - UI models

enum SpotStatus: String, CaseIterable, Codable {
    case free = "Free"
    case occupied = "Occupied"
    case uncertain = "Uncertain"
    case occluded = "Occluded"

    init(fromDBStatus value: Int) {
        switch value {
        case 1: self = .occupied
        case 0: self = .free
        default: self = .uncertain
        }
    }
}

struct ParkingSpot: Identifiable, Codable {
    let id: String              // from Space.id
    let name: String            // display name, e.g. same as id
    let lotName: String         // human-friendly lot name, e.g. "lot_A"
    let category: SpaceCategory
    let status: SpotStatus
    let lastUpdated: Date       // for now, fill with current time
}

// Helper to map from backend models
extension ParkingSpot {
    init(space: Space, lot: Lot) {
        self.id = space.id
        self.name = space.id
        self.lotName = lot.name
        self.category = space.category
        self.status = SpotStatus(fromDBStatus: space.status)
        self.lastUpdated = Date()
    }
}

// MARK: - Drones & Alerts (mock for now)

enum DroneStatus: String {
    case idle = "Idle"
    case patrolling = "Patrolling"
    case rth = "Return to Home"
    case offline = "Offline"
}

struct Drone: Identifiable {
    let id: UUID = UUID()
    let name: String
    let batteryLevel: Double  // 0.0 – 1.0
    let status: DroneStatus
    let zone: String
}

struct AlertItem: Identifiable {
    let id: UUID = UUID()
    let title: String
    let message: String
    let timestamp: Date
    let severity: String      // "Info", "Warning", "Critical"
}


// MARK: - Mock Data

struct MockData {
    static let drones: [Drone] = [
        Drone(name: "Drone 1", batteryLevel: 0.82, status: .patrolling, zone: "lot_A"),
        Drone(name: "Drone 2", batteryLevel: 0.45, status: .rth,        zone: "lot_B"),
        Drone(name: "Drone 3", batteryLevel: 0.93, status: .idle,       zone: "Hangar"),
        Drone(name: "Drone 4", batteryLevel: 0.18, status: .patrolling, zone: "lot_A")
    ]

    static let alerts: [AlertItem] = [
        AlertItem(
            title: "Battery Low",
            message: "Drone 4 battery below 20%. Returning to home.",
            timestamp: Date().addingTimeInterval(-60),
            severity: "Warning"
        ),
        AlertItem(
            title: "Spot 1_2 change",
            message: "Spot 1_2 changed from Free to Occupied.",
            timestamp: Date().addingTimeInterval(-300),
            severity: "Info"
        ),
        AlertItem(
            title: "Occlusion detected",
            message: "lot_B camera view partially blocked. Confidence reduced.",
            timestamp: Date().addingTimeInterval(-900),
            severity: "Info"
        )
    ]
}
