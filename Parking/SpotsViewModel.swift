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
    @Published var isShowingCachedData = false
    @Published var cacheTimestamp: Date?

    private var refreshTask: Task<Void, Never>?
    private var isBackgroundRefreshing = false
    private let cacheURL: URL

    init() {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        cacheURL = (cachesDirectory ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("parking_snapshot_cache.json")

        loadCachedSnapshotOnLaunch()
    }

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
            cacheTimestamp = Date()
            isShowingCachedData = false
            errorMessage = nil
            saveSnapshotToCache(lots: lots, spots: mapped, savedAt: cacheTimestamp ?? Date())
        } catch {
            if error is CancellationError { return }
            if let urlError = error as? URLError, urlError.code == .cancelled { return }

            let didLoadFromCache = loadCachedSnapshotFromDisk()
            if didLoadFromCache {
                isShowingCachedData = true
                if !silent {
                    if let cacheTimestamp {
                        errorMessage = "Offline mode: showing cached data from \(cacheTimestamp.formatted(date: .abbreviated, time: .shortened))."
                    } else {
                        errorMessage = "Offline mode: showing cached data."
                    }
                }
            } else if !silent {
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

private extension SpotsViewModel {
    struct CachedSnapshot: Codable {
        let lots: [Lot]
        let spots: [ParkingSpot]
        let savedAt: Date
    }

    func loadCachedSnapshotOnLaunch() {
        let didLoadCache = loadCachedSnapshotFromDisk()
        if didLoadCache {
            isShowingCachedData = true
        }
    }

    @discardableResult
    func loadCachedSnapshotFromDisk() -> Bool {
        guard let data = try? Data(contentsOf: cacheURL) else { return false }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let snapshot = try? decoder.decode(CachedSnapshot.self, from: data) else {
            return false
        }

        lots = snapshot.lots
        spots = snapshot.spots
        cacheTimestamp = snapshot.savedAt
        return !(snapshot.lots.isEmpty && snapshot.spots.isEmpty)
    }

    func saveSnapshotToCache(lots: [Lot], spots: [ParkingSpot], savedAt: Date) {
        let snapshot = CachedSnapshot(lots: lots, spots: spots, savedAt: savedAt)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }
}
