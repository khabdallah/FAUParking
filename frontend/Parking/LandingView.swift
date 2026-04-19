//
//  LandingView.swift
//  Parking
//
//  Created by Khalid Abdallah on 4/19/26.
//

import SwiftUI

struct LandingView: View {
    @State private var goToApp = false

    var body: some View {
        Group {
            if goToApp {
                MainTabView()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.25),
                            Color.blue.opacity(0.18),
                            Color.white
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 20) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 120, height: 120)
                                .shadow(radius: 10)

                            Image(systemName: "car.fill")
                                .font(.system(size: 46))
                                .foregroundStyle(Color.accentColor)
                        }

                        Text("Smart Parking")
                            .font(.largeTitle.bold())

                        Text("Loading your parking data...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ProgressView()
                            .padding(.top, 10)

                        Spacer()
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            goToApp = true
                        }
                    }
                }
            }
        }
    }
}
