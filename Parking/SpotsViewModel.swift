//
//  SpotsViewModel.swift
//  Parking
//
//  Created by Khalid Abdallah on 12/2/25.
//

import SwiftUI
import Combine

@MainActor
final class SpotsViewModel: ObservableObject {
    /// How often to refresh parking data while the app is in the foreground (seconds).
    static let refreshInterval: TimeInterval = 30

    @Published var lots: [Lot] = []
    @Published var spots: [ParkingSpot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var refreshTask: Task<Void, Never>?
    private var isBackgroundRefreshing = false

    func load(silent: Bool = false) async {
        if silent {
            if isLoading || isBackgroundRefreshing { return }
            isBackgroundRefreshing = true
        } else {
            if isLoading { return }
            isLoading = true
            errorMessage = nil
        }

        defer {
            if silent { isBackgroundRefreshing = false }
            else { isLoading = false }
        }

        do {
            let lots = try await ParkingAPI.shared.fetchLots()
            let spaces = try await ParkingAPI.shared.fetchSpaces()

            let lotById = Dictionary(uniqueKeysWithValues: lots.map { ($0.id, $0) })

            let mapped: [ParkingSpot] = spaces.compactMap { space in
                guard let lot = lotById[space.lotId] else { return nil }
                return ParkingSpot(space: space, lot: lot)
            }

            self.lots = lots
            spots = mapped
        } catch {
            if !silent, !(error is CancellationError) {
                if let urlError = error as? URLError, urlError.code == .cancelled { return }
                errorMessage = (error as? ParkingAPIError)?.errorDescription ?? (error as? LocalizedError)?.errorDescription ?? "Failed to load parking data."
            }
        }
    }

    /// Start periodically refreshing spots while the app is open. Call from the root view when scene becomes active.
    func startPeriodicRefresh() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [interval = Self.refreshInterval] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard !Task.isCancelled else { break }
                await load(silent: true)
            }
        }
    }

    /// Stop periodic refresh (e.g. when app goes to background). Call from the root view when scene becomes inactive.
    func stopPeriodicRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    var freeSpotsCount: Int {
        spots.filter { $0.status == .free }.count
    }

    var occupiedSpotsCount: Int {
        spots.filter { $0.status == .occupied }.count
    }
}
