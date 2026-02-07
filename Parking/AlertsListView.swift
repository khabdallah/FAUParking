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
            List(alerts.sorted { $0.timestamp > $1.timestamp }) { alert in
                AlertRow(alert: alert)
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
                    .background(severityColor(alert.severity).opacity(0.15))
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
        .padding(.vertical, 4)
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
