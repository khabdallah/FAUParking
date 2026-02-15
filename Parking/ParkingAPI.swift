//
//  ParkingAPI.swift
//  Parking
//
//  Created by Khalid Abdallah on 12/2/25.
//

import Foundation

enum ParkingAPIError: LocalizedError {
    case networkUnavailable(underlying: Error)
    case serverError(statusCode: Int)
    case invalidResponse
    case decodingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Unable to reach the server. Check your connection and try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .invalidResponse:
            return "Invalid response from server."
        case .decodingFailed:
            return "Data from the server could not be read. Please try again later."
        }
    }
}

final class ParkingAPI {
    static let shared = ParkingAPI()

    // TODO: change to your actual backend base URL
    // e.g. URL(string: "http://127.0.0.1:8000")! when using a tunnel / local network
    private let baseURL = URL(string: "https://parking.2759359719sw.workers.dev")!

    private let decoder: JSONDecoder

    private init() {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        decoder = d
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = baseURL.appendingPathComponent(path)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw ParkingAPIError.networkUnavailable(underlying: error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ParkingAPIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw ParkingAPIError.serverError(statusCode: http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ParkingAPIError.decodingFailed(underlying: error)
        }
    }

    // MARK: - Public API

    func fetchLots() async throws -> [Lot] {
        // expects GET /api/lots → array of Lot JSON objects
        try await get("/api/lot")
    }

    func fetchSpaces() async throws -> [Space] {
        // expects GET /api/spaces → array of Space JSON objects
        try await get("/api/space")
    }
}
