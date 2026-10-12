//
//  CardioDetailsView.swift
//  Vigor
//
//  Created by Alp Rüzgar on 9.10.2026.
//

import SwiftUI
import MapKit

struct CardioDetailsView: View {
    @Environment(User.self) private var user
    let cardioSession: CardioSession
    var showsToolbar: Bool = true

    private func timeString(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
    
    private var goalString: String? {
        guard cardioSession.goalType != .free, let goalValue = cardioSession.goalValue else { return nil }
        switch cardioSession.goalType {
        case .free:
            return nil
        case .distance:
            return Measurement(value: goalValue, unit: UnitLength.kilometers)
                .formatted(.measurement(width: .abbreviated,
                                        usage: .road,
                                        numberFormatStyle: .number.precision(.fractionLength(0...1))))
        case .duration:
            return timeString(goalValue * 60)
        case .calories:
            return "\(Int(goalValue)) kcal"
        }
    }
    
    private var elapsedString: String { timeString(cardioSession.duration) }
    
    private var distanceString: String {
        cardioSession.distance.formatted(.measurement(width: .abbreviated, usage: .road))
    }
    
    private var averageString: String {
        let km = cardioSession.distanceMeters / 1000
        guard km > 0, cardioSession.duration > 0 else { return "--" }
        if cardioSession.activity.showsPace {
            let pace = Int(cardioSession.duration / km)
            return String(format: "%d:%02d /km", pace / 60, pace % 60)
        }
        return String(format: "%.1f km/h", km / (cardioSession.duration / 3600))
    }
    
    private var caloriesString: String {
        let kcal = user.calories(for: cardioSession.activity, duration: cardioSession.duration)
        return "\(Int(kcal)) kcal"
    }
    
    private var currentGoalValue: Double {
        switch cardioSession.goalType {
        case .free: 0
        case .distance: cardioSession.distanceMeters / 1000
        case .duration: cardioSession.duration / 60
        case .calories: user.calories(for: cardioSession.activity, duration: cardioSession.duration)
        }
    }
    
    private var cardOrder: [Int] {
        switch cardioSession.goalType {
        case .free: [0, 1, 2]
        case .distance: [0, 1, 2]
        case .duration: [1, 0, 2]
        case .calories: [2, 0, 1]
        }
    }
    
    private var infoCards: [InfoCard] {
        let cards = [
            InfoCard(title: "Distance", icon: "ruler", value: distanceString, color: .electricLime),
            InfoCard(title: "Time", icon: "timer", value: elapsedString, color: .white),
            InfoCard(title: "Calories", icon: "flame.fill", value: caloriesString, color: .electricLime)
        ]
        var ordered = cardOrder.map { cards[$0] }
        ordered[0].isMain = true
        ordered[0].goalText = goalString
        return ordered
    }
    
    // Sadece tam (1 km) lap'ler karşılaştırılır; son yarım lap tempoyu yanıltabilir
    private var fastestLap: Lap? {
        guard cardioSession.laps.count > 1 else { return nil }
        return cardioSession.laps
            .filter { $0.distanceMeters >= 1000 }
            .min { $0.duration < $1.duration }
    }
    
    private var coordinates: [CLLocationCoordinate2D] {
        cardioSession.points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.plusJakartaSansBold(size: 20))
                    .neonShadow(.electricLime)
                Text(cardioSession.activity.title)
                    .font(.plusJakartaSansBold(size: 32))
                    .neonShadow(.electricLime)
                Spacer()
            }
            .foregroundStyle(.electricLime)
            
            Text(cardioSession.date.formatted(date: .abbreviated, time: .shortened))
                .font(.spaceGrotesk(size: 14))
                .foregroundStyle(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Map(initialPosition: .automatic) {
                if let first = coordinates.first {
                    Marker("Start", systemImage: "flag", coordinate: first)
                        .tint(.green)
                }
                if let last = coordinates.last {
                    Marker("Finish", systemImage: "flag.checkered", coordinate: last)
                        .tint(.red)
                }
                if coordinates.count > 1 {
                    MapPolyline(coordinates: coordinates)
                        .stroke(.blue, lineWidth: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .allowsHitTesting(false)
            
            VStack(spacing: 8) {
                infoCards[0]
                if cardioSession.goalType != .free {
                    ProgressBar(goal: CardioGoal(type: cardioSession.goalType, value: cardioSession.goalValue ?? 0),
                                current: currentGoalValue,
                                showsOvershoot: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .card()
            
            HStack(spacing: 12) {
                infoCards[1]
                InfoCard(title: cardioSession.activity.showsPace ? "Avg Pace" : "Avg Speed",
                         icon: "stopwatch", value: averageString, color: .iceBlue)
            }
            HStack(spacing: 12) {
                infoCards[2]
                InfoCard(title: "Laps", icon: "repeat", value: "\(cardioSession.laps.count)", color: .white)
            }
            
            if !cardioSession.laps.isEmpty {
                VStack(spacing: 12) {
                    Text("Laps")
                        .font(.plusJakartaSans(size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(spacing: 0) {
                        ForEach(cardioSession.laps, id: \.self) { lap in
                            LapRow(lap: lap, isFastest: lap == fastestLap)
                            if lap != cardioSession.laps.last {
                                Divider().overlay(.white.opacity(0.1))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .card()
                }
            }
        }
        .modifier(CardioDetailsToolbarModifier(isEnabled: showsToolbar, title: cardioSession.activity.title))
    }
}

private struct CardioDetailsToolbarModifier: ViewModifier {
    var isEnabled: Bool
    var title: String

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .navigationBarTitleDisplayMode(.inline)
                .customToolbar(title: title)
        } else {
            content
        }
    }
}
