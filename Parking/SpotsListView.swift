//
//  SpotsListView.swift
//  Parking
//
//  Created by Khalid Abdallah on 11/24/25.
//

import SwiftUI

struct SpotsListView: View {
    @EnvironmentObject var viewModel: SpotsViewModel

    private var contentPhase: Int {
        if viewModel.isLoading && viewModel.spots.isEmpty { return 0 }
        if viewModel.errorMessage != nil && viewModel.spots.isEmpty { return 1 }
        return 2
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
                } else {
                    List(viewModel.spots) { spot in
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
            .navigationTitle("Parking Spots")
        }
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
