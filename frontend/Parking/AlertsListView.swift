//
//  AlertsListView.swift
//  Parking
//
//  Created by Khalid Abdallah on 11/24/25.
//

import SwiftUI

struct AlertsListView: View {
    let alerts: [AlertItem]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.14), Color.blue.opacity(0.08), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                List(alerts.sorted { $0.timestamp > $1.timestamp }) { alert in
                    AlertRow(alert: alert)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .animation(.easeInOut(duration: 0.25), value: alerts.count)
            .navigationTitle("Alerts")
        }
    }
}

struct AlertRow: View {
    let alert: AlertItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(alert.title)
                    .font(.headline)
                Spacer()
                Text(alert.severity)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(severityColor(alert.severity).opacity(0.18))
                    .foregroundColor(severityColor(alert.severity))
                    .cornerRadius(6)
            }

            Text(alert.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(alert.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(severityColor(alert.severity).opacity(0.15), lineWidth: 1)
        )
    }

    private func severityColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "critical": return .red
        case "warning": return .orange
        default: return .blue
        }
    }
}

#Preview {
    AlertsListView(alerts: MockData.alerts)
}
