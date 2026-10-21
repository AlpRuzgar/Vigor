//
//  CardioListView.swift
//  Vigor
//
//  Created by Alp Rüzgar on 13.10.2026.
//

import SwiftUI
import SwiftData

struct CardioListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CardioSession.date, order: .reverse)
    private var sessions: [CardioSession]
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if sessions.isEmpty {
                    ContentUnavailableView{
                        Label("You haven't done any cardio exercises yet!", systemImage: "xmark.circle")
                            .foregroundStyle(.voltRed)
                            .font(.spaceGrotesk(size: 24))
                    }
                    .card()
                } else {
                    ForEach(sessions) { session in
                        NavigationLink {
                            ScrollView {
                                CardioDetailsView(cardioSession: session)
                                    .padding()
                            }
                            .background(.coldBlack)
                        } label: {
                            CardioSessionRow(session: session)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                delete(session)
                            }
                        }
                        .contextMenu {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                delete(session)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .swipeActionsContainerIfAvailable()
        .background(.coldBlack)
        .navigationBarTitleDisplayMode(.inline)
        .customToolbar(title: "Cardios")
    }

    private func delete(_ session: CardioSession) {
        withAnimation {
            modelContext.delete(session)
        }
    }
}

struct CardioSessionRow: View {
    @Environment(User.self) private var user
    let session: CardioSession

    private var durationString: String {
        Duration.seconds(session.duration).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }

    private var distanceString: String {
        session.distance.formatted(.measurement(width: .abbreviated, usage: .road))
    }

    // Ortalama tempo (koşu/yürüyüş) ya da ortalama hız (bisiklet)
    private var averageString: String {
        let km = session.distanceMeters / 1000
        guard km > 0, session.duration > 0 else { return "--" }
        if session.activity.showsPace {
            let pace = Int(session.duration / km)
            return String(format: "%d:%02d", pace / 60, pace % 60)
        }
        return String(format: "%.1f", km / (session.duration / 3600))
    }

    private var caloriesString: String {
        "\(Int(user.calories(for: session.activity, duration: session.duration)))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: session.activity.systemImage)
                    .font(.system(size: 20))
                    .foregroundStyle(.electricLime)
                    .frame(width: 44, height: 44)
                    .background(.electricLime.opacity(0.15))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.date.formatted(.dateTime.weekday(.wide).day().month()))
                        .font(.plusJakartaSansBold(size: 16))
                        .foregroundStyle(.white)
                    Text(session.date.formatted(date: .omitted, time: .shortened))
                        .font(.spaceGrotesk(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(durationString)
                        .font(.spaceGroteskBold(size: 16))
                        .foregroundStyle(.electricLime)
                    Text("Duration")
                        .font(.spaceGrotesk(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            HStack(spacing: 8) {
                WorkoutStat(value: distanceString, label: "Distance")
                WorkoutStat(value: averageString, label: session.activity.showsPace ? "Avg /km" : "Avg km/h")
                WorkoutStat(value: caloriesString, label: "kcal")
            }

            HStack(spacing: 6) {
                MuscleTag(text: session.activity.title)
                if session.goalType != .free {
                    MuscleTag(text: "Goal: \(session.goalType.name)")
                }
            }
        }
        .padding()
        .card()
    }
}
