//
//  DashboardView.swift
//  Parking
//
//  Created by Khalid Abdallah on 11/24/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var spotsViewModel: SpotsViewModel

    @State private var selectedCategory: SpaceCategory?
    @State private var selectedLotId: String?
    @State private var selectedSpotForInfo: ParkingSpot?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.14),
                        Color.blue.opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        
                        dashboardHeader

                        // Favorite lots (quick pick)
                            if !spotsViewModel.favoriteLotsOrdered.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Favorite lots")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(spotsViewModel.favoriteLotsOrdered, id: \.id) { lot in
                                            FavoriteLotChip(
                                            title: lot.name,
                                            freeCount: spotsViewModel.freeSpotsCount(forLotId: lot.id),
                                            isSelected: selectedLotId == lot.id
                                            ) {
                                                selectedLotId = lot.id
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                        // Lot filter
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Choose a lot")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                Menu {
                                    Button("All lots") {
                                        selectedLotId = nil
                                    }

                                    if !spotsViewModel.lots.isEmpty {
                                        Divider()
                                    }

                                    ForEach(spotsViewModel.lotsOrderedFavoritesFirst, id: \.id) { lot in
                                        Button {
                                            selectedLotId = lot.id
                                        } label: {
                                            Label {
                                                Text(lot.name)
                                            } icon: {
                                                Image(systemName: spotsViewModel.isFavoriteLot(id: lot.id) ? "star.fill" : "star")
                                                    .foregroundStyle(spotsViewModel.isFavoriteLot(id: lot.id) ? Color.yellow : Color.secondary.opacity(0.35))
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(currentLotDisplayName)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.thinMaterial)
                                    .cornerRadius(12)
                                }

                                if let sid = selectedLotId,
                                   spotsViewModel.lots.contains(where: { $0.id == sid }) {
                                    Button {
                                        spotsViewModel.toggleFavorite(lotId: sid)
                                    } label: {
                                        Image(systemName: spotsViewModel.isFavoriteLot(id: sid) ? "star.fill" : "star")
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(spotsViewModel.isFavoriteLot(id: sid) ? Color.yellow : Color.secondary)
                                            .frame(width: 40, height: 36)
                                            .background(.thinMaterial)
                                            .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(
                                        spotsViewModel.isFavoriteLot(id: sid)
                                        ? "Remove lot from favorites"
                                        : "Add lot to favorites"
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // 2D lot layout / map
                        if let selectedLotId,
                           let lot = spotsViewModel.lots.first(where: { $0.id == selectedLotId }) {
                            Lot2DView(
                                lotName: lot.name,
                                spots: filteredSpots,
                                selectedCategory: selectedCategory,
                                onSpotTap: { spot in
                                    selectedSpotForInfo = spot
                                }
                            )
                            .padding(.horizontal)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                .frame(height: 220)
                                .overlay {
                                    VStack(spacing: 8) {
                                        Image(systemName: "map")
                                            .font(.system(size: 40))
                                        Text("Live Map View")
                                            .font(.headline)
                                        Text("Select a lot to see its layout.")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                        }

                        

                        

                        // Stats
                        HStack(spacing: 12) {
                            StatCard(
                                title: "Free Spots",
                                value: "\(freeSpotsCount)",
                                systemImage: "checkmark.circle.fill",
                                tint: .green
                            )

                            StatCard(
                                title: "Occupied",
                                value: "\(occupiedSpotsCount)",
                                systemImage: "xmark.circle.fill",
                                tint: .red
                            )
                        }
                        .padding(.horizontal)
                        .animation(.easeInOut(duration: 0.25), value: freeSpotsCount)
                        .animation(.easeInOut(duration: 0.25), value: occupiedSpotsCount)

                        // Category filters & summary chips
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Filter by permit type")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 104), spacing: 8)],
                                alignment: .leading,
                                spacing: 8
                            ) {
                                CategoryChip(
                                    title: "All",
                                    count: freeCount(for: nil),
                                    isSelected: selectedCategory == nil
                                ) {
                                    selectedCategory = nil
                                }

                                CategoryChip(
                                    title: "White",
                                    count: freeCount(for: .white),
                                    isSelected: selectedCategory == .white
                                ) {
                                    selectedCategory = .white
                                }

                                CategoryChip(
                                    title: "Blue",
                                    count: freeCount(for: .blue),
                                    isSelected: selectedCategory == .blue
                                ) {
                                    selectedCategory = .blue
                                }

                                CategoryChip(
                                    title: "Green",
                                    count: freeCount(for: .green),
                                    isSelected: selectedCategory == .green
                                ) {
                                    selectedCategory = .green
                                }

                                CategoryChip(
                                    title: "Red",
                                    count: freeCount(for: .red),
                                    isSelected: selectedCategory == .red
                                ) {
                                    selectedCategory = .red
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: selectedCategory)

                            Text(selectedCategoryDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)

                        if spotsViewModel.isLoading {
                            ProgressView("Refreshing data…")
                                .padding(.top, 8)
                                .transition(.opacity)
                        }

                        if let error = spotsViewModel.errorMessage {
                            VStack(spacing: 8) {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                Button("Retry") {
                                    Task { await spotsViewModel.load() }
                                }
                                .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                            .transition(.opacity)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: spotsViewModel.isLoading)
            .animation(.easeInOut(duration: 0.25), value: spotsViewModel.errorMessage ?? "")
            .refreshable {
                await spotsViewModel.load()
            }
            .navigationTitle("Dashboard")
            .sheet(item: $selectedSpotForInfo) { spot in
                SpotDashboardInfoSheet(spot: spot)
            }
        }
    }
}

private extension DashboardView {
    var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Find parking faster")
                .font(.title2.bold())

            Text(
                selectedLotId == nil
                ? "Choose a lot to view available spaces."
                : "Tap a space on the map to see details."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    var filteredSpots: [ParkingSpot] {
        guard let selectedLotId,
              let lot = spotsViewModel.lots.first(where: { $0.id == selectedLotId }) else {
            return spotsViewModel.spots
        }

        return spotsViewModel.spots.filter { $0.lotName == lot.name }
    }

    var freeSpotsCount: Int {
        filteredSpots.filter { $0.status == .free }.count
    }

    var occupiedSpotsCount: Int {
        filteredSpots.filter { $0.status == .occupied }.count
    }

    var currentLotDisplayName: String {
        guard let selectedLotId,
              let lot = spotsViewModel.lots.first(where: { $0.id == selectedLotId }) else {
            return "All lots"
        }
        return lot.name
    }

    func freeCount(for category: SpaceCategory?) -> Int {
        filteredSpots.filter { spot in
            guard spot.status == .free else { return false }
            if let category {
                return spot.category == category
            } else {
                return true
            }
        }.count
    }

    var selectedCategoryDescription: String {
        switch selectedCategory {
        case nil:
            return "Showing all free spaces across all permits."
        case .some(.white):
            return "Showing free white-permit spaces."
        case .some(.blue):
            return "Showing free blue-permit spaces."
        case .some(.green):
            return "Showing free green-permit spaces."
        case .some(.red):
            return "Showing free red-permit spaces."
        }
    }
}

private struct FavoriteLotChip: View {
    let title: String
    let freeCount: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.yellow)
                Text(title)
                    .lineLimit(1)
                Text("\(freeCount)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor.opacity(0.22) : Color.secondary.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(freeCount) free spaces")
    }
}

struct CategoryChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Spacer(minLength: 0)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .layoutPriority(1)
                Text("\(count)")
                    .font(.caption)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [Color.accentColor.opacity(0.26), Color.blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.secondary.opacity(0.08), Color.secondary.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundStyle(isSelected ? Color.accentColor : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.accentColor.opacity(0.32) : Color.clear, lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
            .shadow(color: isSelected ? Color.accentColor.opacity(0.18) : .clear, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.title2)
                .bold()
                .contentTransition(.numericText())
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: tint.opacity(0.14), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Spot info (dashboard tap)

private struct SpotDashboardInfoSheet: View {
    let spot: ParkingSpot
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spot \(spot.name)")
                        .font(.title3.weight(.semibold))
                    Text(spot.lotName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .font(.body.weight(.semibold))
            }

            Divider()

            HStack {
                Text("Permit")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(spot.category.rawValue.capitalized)
            }
            .font(.subheadline)

            HStack {
                Text("Status")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(spot.status.rawValue)
                    .fontWeight(.medium)
            }
            .font(.subheadline)

            HStack {
                Text("Last updated")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(spot.lastUpdated.formatted(date: .abbreviated, time: .shortened))
            }
            .font(.subheadline)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - 2D lot layout

struct Lot2DView: View {
    let lotName: String
    let spots: [ParkingSpot]
    let selectedCategory: SpaceCategory?
    let onSpotTap: (ParkingSpot) -> Void

    init(
        lotName: String,
        spots: [ParkingSpot],
        selectedCategory: SpaceCategory?,
        onSpotTap: @escaping (ParkingSpot) -> Void = { _ in }
    ) {
        self.lotName = lotName
        self.spots = spots
        self.selectedCategory = selectedCategory
        self.onSpotTap = onSpotTap
    }

    private struct SpotCoordinate: Hashable {
        let row: Int
        let col: Int
    }

    private var coordinateMap: [SpotCoordinate: ParkingSpot] {
        if isWestDelrayLot {
            return coordinateMapForWestDelray()
        }

        var map: [SpotCoordinate: ParkingSpot] = [:]
        for spot in spots {
            guard let coord = parseCoordinates(from: spot.id) else { continue }
            map[coord] = spot
        }
        return map
    }

    private var isWestDelrayLot: Bool {
        lotName.lowercased().contains("west delray")
    }

    private var gridSize: (rows: Int, cols: Int) {
        let coords = coordinateMap.keys
        let rows = coords.map(\.row).max() ?? 0
        let cols = coords.map(\.col).max() ?? 0
        return (rows, cols)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lotName)
                        .font(.headline)
                    Text("2D lot layout")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color.accentColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    if gridSize.rows > 0, gridSize.cols > 0 {
                        VStack(spacing: 0) {
                            Spacer(minLength: 4)
                            ForEach(1...gridSize.rows, id: \.self) { row in
                                HStack(spacing: 6) {
                                    ForEach(1...gridSize.cols, id: \.self) { col in
                                        let coord = SpotCoordinate(row: row, col: col)
                                        if let spot = coordinateMap[coord] {
                                            spotCell(for: spot)
                                        } else {
                                            Rectangle()
                                                .fill(Color.clear)
                                                .frame(width: 22, height: 32)
                                        }
                                    }
                                }

                                // Add a "drive lane" between the two rows to simulate a parking lot.
                                if row == 1 && gridSize.rows > 1 {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.12))
                                        .frame(height: 20)
                                        .overlay(
                                            Rectangle()
                                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                                .foregroundColor(Color.gray.opacity(0.35))
                                        )
                                        .padding(.horizontal, 2)
                                        .padding(.vertical, 6)
                                }
                            }
                            Spacer(minLength: 4)
                        }
                        .padding(10)
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "questionmark.circle")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("Layout unavailable for this lot.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 220)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)

            HStack(spacing: 12) {
                legendItem(color: statusColor(for: .free), label: "Free")
                legendItem(color: statusColor(for: .occupied), label: "Occupied")
                legendItem(color: statusColor(for: .uncertain), label: "Uncertain")
                legendItem(color: statusColor(for: .occluded), label: "Occluded")
                Spacer()
                if let selectedCategory = selectedCategory {
                    Text("\(selectedCategory.rawValue.capitalized) highlighted")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Coordinate helpers

    private func parseCoordinates(from id: String) -> SpotCoordinate? {
        let parts = id.split(separator: "_")
        guard parts.count == 2,
              let row = Int(parts[0]),
              let col = Int(parts[1]) else {
            return nil
        }
        return SpotCoordinate(row: row, col: col)
    }

    /// Special-case layout: for West Delray lot, spaces numbered 1–13 on the top row,
    /// and the remaining spaces on the bottom row.
    private func coordinateMapForWestDelray() -> [SpotCoordinate: ParkingSpot] {
        var result: [SpotCoordinate: ParkingSpot] = [:]

        // Extract a numeric index for each spot, preferring the display name, then id.
        let indexedSpots: [(spot: ParkingSpot, index: Int)] = spots.compactMap { spot in
            let number = extractNumber(from: spot.name) ?? extractNumber(from: spot.id)
            guard let n = number, n > 0 else { return nil }
            return (spot, n)
        }
        .sorted { lhs, rhs in
            if lhs.index != rhs.index { return lhs.index < rhs.index }
            return lhs.spot.id < rhs.spot.id
        }

        for (spot, n) in indexedSpots {
            let row: Int
            let col: Int

            if n <= 13 {
                row = 1
                col = n
            } else {
                row = 2
                col = n - 13
            }

            result[SpotCoordinate(row: row, col: col)] = spot
        }

        return result
    }

    /// Extracts the last contiguous sequence of digits from a string as an Int.
    private func extractNumber(from string: String) -> Int? {
        let components = string.split(whereSeparator: { !$0.isNumber })
        guard let lastDigits = components.last,
              let value = Int(lastDigits) else {
            return nil
        }
        return value
    }

    private func spotCell(for spot: ParkingSpot) -> some View {
        let isDimmed: Bool
        if let selectedCategory {
            isDimmed = spot.category != selectedCategory
        } else {
            isDimmed = false
        }

        return Button {
            onSpotTap(spot)
        } label: {
            RoundedRectangle(cornerRadius: 4)
                .fill(statusColor(for: spot.status))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(categoryColor(for: spot.category), lineWidth: 1)
                )
                .opacity(isDimmed ? 0.25 : 1.0)
                .frame(width: 22, height: 32)
                .shadow(color: statusColor(for: spot.status).opacity(0.24), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(spot.name), \(spot.status.rawValue)")
        .accessibilityHint("Shows spot details")
    }

    private func legendItem(color: Color, label: String) -> some View {
        return HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 14, height: 10)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func statusColor(for status: SpotStatus) -> Color {
        switch status {
        case .free:
            return Color.green.opacity(0.7)
        case .occupied:
            return Color.red.opacity(0.8)
        case .uncertain:
            return Color.orange.opacity(0.8)
        case .occluded:
            return Color.gray.opacity(0.7)
        }
    }

    private func categoryColor(for category: SpaceCategory) -> Color {
        switch category {
        case .white:
            return Color.white.opacity(0.9)
        case .blue:
            return Color.blue.opacity(0.9)
        case .green:
            return Color.green.opacity(0.9)
        case .red:
            return Color.red.opacity(0.9)
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(SpotsViewModel())
}
