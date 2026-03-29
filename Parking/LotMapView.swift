//
//  LotMapView.swift
//  Parking
//
//  Map of parking lots with tappable pins. Pins are placed by geocoding each lot’s address.
//

import MapKit
import SwiftUI
import Combine

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

/// Fallback coordinates only for lots with no address (keyed by lot id).
private let fallbackCoordinates: [String: CLLocationCoordinate2D] = [
    "1": CLLocationCoordinate2D(latitude: 26.4584, longitude: -80.0734),
    "2": CLLocationCoordinate2D(latitude: 26.4600, longitude: -80.0750),
]

private func region(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
    guard !coordinates.isEmpty else {
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 26.4584, longitude: -80.0734),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    }
    let lats = coordinates.map(\.latitude)
    let lons = coordinates.map(\.longitude)
    let minLat = lats.min()!
    let maxLat = lats.max()!
    let minLon = lons.min()!
    let maxLon = lons.max()!
    let center = CLLocationCoordinate2D(
        latitude: (minLat + maxLat) / 2,
        longitude: (minLon + maxLon) / 2
    )
    let span = MKCoordinateSpan(
        latitudeDelta: max(0.01, (maxLat - minLat) * 1.4),
        longitudeDelta: max(0.01, (maxLon - minLon) * 1.4)
    )
    return MKCoordinateRegion(center: center, span: span)
}

@MainActor
private final class LotGeocoder: ObservableObject {
    /// Resolved coordinates by lot id.
    @Published var coordinatesByLotId: [String: CLLocationCoordinate2D] = [:]
    /// Cache by address string to avoid re-geocoding the same address.
    private var cache: [String: CLLocationCoordinate2D] = [:]

    func resolveCoordinates(for lots: [Lot]) async {
        for lot in lots {
            if let lat = lot.latitude, let lon = lot.longitude {
                coordinatesByLotId[lot.id] = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                continue
            }
            guard let address = lot.address, !address.isEmpty else {
                if let fallback = fallbackCoordinates[lot.id] {
                    coordinatesByLotId[lot.id] = fallback
                }
                continue
            }
            if let cached = cache[address] {
                coordinatesByLotId[lot.id] = cached
                continue
            }
            guard let request = MKGeocodingRequest(addressString: address) else { continue }
            do {
                let mapItems: [MKMapItem] = try await withCheckedThrowingContinuation { continuation in
                    request.getMapItems { items, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        continuation.resume(returning: items ?? [])
                    }
                }
                guard let first = mapItems.first else { continue }
                let coord = first.location.coordinate
                cache[address] = coord
                coordinatesByLotId[lot.id] = coord
            } catch {
                if let fallback = fallbackCoordinates[lot.id] {
                    coordinatesByLotId[lot.id] = fallback
                }
            }
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s between requests
        }
    }
}

struct LotMapView: View {
    @EnvironmentObject var spotsViewModel: SpotsViewModel
    @StateObject private var geocoder = LotGeocoder()
    @State private var selectedLot: Lot?
    @State private var cameraPosition: MapCameraPosition = .automatic

    private var lots: [Lot] { spotsViewModel.lots }

    /// Lots that have a resolved coordinate (from API, geocoded address, or fallback).
    private var lotsWithCoordinates: [(Lot, CLLocationCoordinate2D)] {
        var result: [(Lot, CLLocationCoordinate2D)] = []
        for lot in lots {
            if let coord = geocoder.coordinatesByLotId[lot.id] {
                result.append((lot, coord))
            }
        }
        return result
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.12), Color.blue.opacity(0.08), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            mainMap
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.top, 8)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 6)
        }
        .mapStyle(.standard(elevation: .realistic))
        .onChange(of: lots) { _, newLots in
            if !newLots.isEmpty {
                Task { await geocoder.resolveCoordinates(for: newLots) }
            }
        }
        .onChange(of: geocoder.coordinatesByLotId) { _, coords in
            updateCameraPosition(from: coords)
        }
        .onAppear {
            if !lots.isEmpty {
                Task { await geocoder.resolveCoordinates(for: lots) }
            }
        }
        .sheet(item: $selectedLot) { lot in
            LotPinSheet(lot: lot, spotCount: spotCount(for: lot))
        }
        .navigationTitle("Map")
    }

    private var mainMap: some View {
        Map(position: $cameraPosition, selection: $selectedLot) {
            ForEach(lotsWithCoordinates, id: \.0.id) { lot, coord in
                Marker(lot.name, systemImage: "parkingsign.circle", coordinate: coord)
                    .tag(lot)
            }
        }
    }

    private func updateCameraPosition(from coords: [String: CLLocationCoordinate2D]) {
        let coordList = Array(coords.values)
        if !coordList.isEmpty {
            cameraPosition = .region(region(for: coordList))
        }
    }

    private func spotCount(for lot: Lot) -> Int {
        spotsViewModel.spots.filter { $0.lotName == lot.name }.count
    }
}

struct LotPinSheet: View {
    let lot: Lot
    let spotCount: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(lot.name)
                    .font(.title2.bold())

                if let address = lot.address, !address.isEmpty {
                    Label(address, systemImage: "mappin.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("\(spotCount) parking spot\(spotCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.16), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LotMapView()
            .environmentObject(SpotsViewModel())
    }
}
