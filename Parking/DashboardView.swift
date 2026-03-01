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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Map placeholder
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .frame(height: 220)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "map")
                                    .font(.system(size: 40))
                                Text("Live Map View")
                                    .font(.headline)
                                Text("Parking lots and available spaces")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)

                    // Lot filter
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Filter by lot")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Menu {
                            Button("All lots") {
                                selectedLotId = nil
                            }

                            if !spotsViewModel.lots.isEmpty {
                                Divider()
                            }

                            ForEach(spotsViewModel.lots, id: \.id) { lot in
                                Button(lot.name) {
                                    selectedLotId = lot.id
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
                    }
                    .padding(.horizontal)

                    // Stats
                    HStack(spacing: 12) {
                        StatCard(
                            title: "Free Spots",
                            value: "\(freeSpotsCount)",
                            systemImage: "checkmark.circle"
                        )

                        StatCard(
                            title: "Occupied",
                            value: "\(occupiedSpotsCount)",
                            systemImage: "xmark.circle"
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

                        HStack(spacing: 8) {
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
                        }

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
            .animation(.easeInOut(duration: 0.25), value: spotsViewModel.isLoading)
            .animation(.easeInOut(duration: 0.25), value: spotsViewModel.errorMessage ?? "")
            .refreshable {
                await spotsViewModel.load()
            }
            .navigationTitle("Dashboard")
        }
    }
}

private extension DashboardView {
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
        }
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
                Text(title)
                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
            .foregroundStyle(isSelected ? Color.accentColor : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
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
        .background(.thinMaterial)
        .cornerRadius(14)
    }
}

#Preview {
    DashboardView()
        .environmentObject(SpotsViewModel())
}
