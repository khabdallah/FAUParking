//
//  SpotsListView.swift
//  Parking
//
//  Created by Khalid Abdallah on 11/24/25.
//

import SwiftUI

struct SpotsListView: View {
    @EnvironmentObject var viewModel: SpotsViewModel
    @State private var statusFilter: SpotStatus? = nil
    @State private var lotFilter: String? = nil

    private var contentPhase: Int {
        if viewModel.isLoading && viewModel.spots.isEmpty { return 0 }
        if viewModel.errorMessage != nil && viewModel.spots.isEmpty { return 1 }
        if filteredSpots.isEmpty { return 2 }
        return 3
    }

    private var lotNames: [String] {
        let names = Set(viewModel.spots.map(\.lotName))
        return names.sorted()
    }

    private var filteredSpots: [ParkingSpot] {
        viewModel.spots.filter { spot in
            let matchesLot = lotFilter == nil || spot.lotName == lotFilter
            let matchesStatus = statusFilter == nil || spot.status == statusFilter
            return matchesLot && matchesStatus
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.spots.isEmpty {
                    ProgressView("Loading spots…")
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if let error = viewModel.errorMessage, viewModel.spots.isEmpty {
                    VStack(spacing: 12) {
                        Text(error)
                        Button("Retry") {
                            Task { await viewModel.load() }
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if filteredSpots.isEmpty {
                    VStack(spacing: 16) {
                        ContentUnavailableView(
                            "No spots match filter",
                            systemImage: "line.3.horizontal.decrease.circle",
                            description: Text(emptyFilterDescription)
                        )
                        Button("Clear filters") {
                            lotFilter = nil
                            statusFilter = nil
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    List(filteredSpots) { spot in
                        NavigationLink {
                            SpotDetailView(spot: spot)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Spot \(spot.name)")
                                        .font(.headline)
                                    Text(spot.lotName)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    Text("Category: \(spot.category.rawValue)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text("Last updated \(spot.lastUpdated, style: .time)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(spot.status.rawValue)
                                    .font(.subheadline)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(statusColor(spot.status).opacity(0.15))
                                    .foregroundColor(statusColor(spot.status))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.load()
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: contentPhase)
            .animation(.easeInOut(duration: 0.25), value: statusFilter?.rawValue ?? "All")
            .animation(.easeInOut(duration: 0.25), value: lotFilter ?? "")
            .navigationTitle("Parking Spots")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Section("Lot") {
                            Button {
                                lotFilter = nil
                            } label: {
                                Label("All lots", systemImage: lotFilter == nil ? "checkmark.circle.fill" : "circle")
                            }
                            ForEach(lotNames, id: \.self) { lotName in
                                Button {
                                    lotFilter = lotName
                                } label: {
                                    Label(lotName, systemImage: lotFilter == lotName ? "checkmark.circle.fill" : "circle")
                                }
                            }
                        }
                        Section("Status") {
                            Button {
                                statusFilter = nil
                            } label: {
                                Label("All statuses", systemImage: statusFilter == nil ? "checkmark.circle.fill" : "circle")
                            }
                            ForEach(SpotStatus.allCases, id: \.self) { status in
                                Button {
                                    statusFilter = status
                                } label: {
                                    Label(status.rawValue, systemImage: statusFilter == status ? "checkmark.circle.fill" : "circle")
                                }
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .disabled(viewModel.spots.isEmpty)
                }
            }
        }
    }

    private var emptyFilterDescription: String {
        var parts: [String] = []
        if let lot = lotFilter { parts.append("lot \(lot)") }
        if let status = statusFilter { parts.append(status.rawValue.lowercased()) }
        if parts.isEmpty { return "No spots." }
        return "No spots matching \(parts.joined(separator: " and "))."
    }

    private func statusColor(_ status: SpotStatus) -> Color {
        switch status {
        case .free: return .green
        case .occupied: return .red
        case .uncertain: return .orange
        case .occluded: return .gray
        }
    }
}

#Preview {
    SpotsListView()
        .environmentObject(SpotsViewModel())
}
