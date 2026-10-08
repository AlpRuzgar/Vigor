//
//  RunningView.swift
//  MyApp
//
//  Created by Alp Rüzgar on 1.10.2026.
//

import SwiftUI
import MapKit
import SwiftData

enum Stage {
    case idle
    case active
    case ended
}

struct CardioView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var stage: Stage = .ended
    @State private var isVisible = false
    @State private var showEndConfirmation = false
    @State private var tracker = CardioTracker()
    
    @State private var selectedActivity: CardioActivity = .running
    @State private var selectedTargetType: TargetType = .free
    @State private var targetValue: Double = 5
    @State private var cardOrder: [Int] = [0, 1, 2]
    
    var infoCards: [InfoCard] {
        let cards = [
            InfoCard(title: "Distance", icon: "ruler", value: distanceString, color: .electricLime),
            InfoCard(title: "Time", icon: "timer", value: elapsedString, color: .white),
            InfoCard(title: "Calories", icon: "flame.fill", value: "calories", color: .electricLime)
        ]
        var ordered = cardOrder.map { cards[$0] }
        ordered[0].isMain = true
        ordered[0].targetText = goalString
        return ordered
    }
    
    private func timeString(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    private var goalString: String? {
        let goal = tracker.cardioGoal
        switch goal.type {
        case .free:
            return nil
        case .distance: // değer km
            return Measurement(value: goal.value, unit: UnitLength.kilometers)
                .formatted(.measurement(width: .abbreviated,
                                        usage: .road,
                                        numberFormatStyle: .number.precision(.fractionLength(0...1))))
        case .duration: // değer dakika
            return timeString(goal.value * 60)
        }
    }
    
    private var elapsedString: String {
        timeString(tracker.elapsed)
    }
    
    private var distanceString: String {
        Measurement(value: tracker.distance, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
    }
        
    private var paceString: String {
        guard let pace = tracker.currentPace, pace < 1800 else { return "--:-- /km" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
        
    var isPaused: Bool { tracker.state == .paused }
    
    var body: some View {
        ScrollView {
            VStack (spacing: 20){
                VStack {
                    switch stage {
                    case .idle:
                        startingMenu()
                    case .active:
                        activeMenu()
                    case .ended:
                        endedMenu()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .background(.coldBlack)
        .scrollClipDisabled()
        
        .onAppear {
            if tracker.lm.authorizationStatus == .notDetermined {
                tracker.lm.requestAuthorization()
            }
            tracker.lm.startUpdatingLocation()
        }
    }
    
    
    @ViewBuilder
    private func startingMenu() -> some View {
        VStack (spacing: 32) {
            HStack{
                Image(systemName: "play.fill")
                    .font(.plusJakartaSansBold(size: 20))
                    .opacity(isVisible ? 0.2 : 1)
                    .neonShadow(.electricLime)
                Text("Start a Run")
                    .font(.plusJakartaSansBold(size: 32))
                Spacer()
            }
            .foregroundStyle(.electricLime)

            ForecastView(location: tracker.lm.currentLocation)
            
            VStack{
                Text("Aktivite seç")
                    .foregroundStyle(.white)
                HStack{
                    ForEach(CardioActivity.allCases, id: \.self) { activity in
                        PickerElement(selected: $selectedActivity, activity: activity, isSelected: selectedActivity == activity)
                            .onTapGesture {
                                withAnimation {
                                    selectedActivity = activity
                                }
                            }
                    }
                }
                .card()
            }
                        
            VStack(spacing: 12) {
                Text("Hedef Tipi")
                    .foregroundStyle(.white)
                    .font(.plusJakartaSans(size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))]){
                    ForEach(TargetType.allCases, id: \.self) { type in
                        TargetOption(targetValue: $targetValue ,type: type, isSelected: selectedTargetType == type)
                            .onTapGesture {
                                withAnimation {
                                    selectedTargetType = type
                                    targetValue = selectedTargetType.defaultValue
                                }
                            }
                    }
                }
                .padding(8)
                .card()
            }
            
            VStack {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.electricLime)
                    Text("Target Type: \(selectedTargetType.name)")
                        .font(.plusJakartaSans(size: 16))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                CustomStepper(type: selectedTargetType, value: $targetValue)
            }
            
            
            Button("Start Run") {
                tracker.start(activity: selectedActivity, cardioGoal: CardioGoal(type: selectedTargetType, value: targetValue))
                if selectedTargetType != .free {
                    let removed = cardOrder.remove(at: selectedTargetType.arrayIndex)
                    cardOrder.insert(removed, at: 0)
                }
                withAnimation(.spring) {
                    stage = .active
                }
            }
            .buttonStyle(.neon(foregroundColor: .coldBlack, backgroundColor: .electricLime))
        }
    }
    
    @ViewBuilder
    private func activeMenu() -> some View {
        VStack(spacing: 20) {
            HStack{
                Image(systemName: "record.circle")
                    .font(.plusJakartaSansBold(size: 20))
                    .foregroundStyle(.red)
                    .neonShadow(.red)
                    .opacity(isVisible ? 0.2 : 1)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isVisible)
                Text("Active Run")
                    .font(.plusJakartaSansBold(size: 32))
                    .foregroundStyle(.electricLime)
                    .neonShadow(.electricLime)
                
                Spacer()
            }
            .onAppear {
                isVisible = true
            }
            
            Map(position: $cameraPosition) {
                UserAnnotation()
                if tracker.locations.count > 1 {
                    MapPolyline(coordinates: tracker.locations.map(\.coordinate))
                        .stroke(.blue, lineWidth: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                VStack(spacing: 8) {
                    infoCards[0]
                    ProgressBar(goal: CardioGoal(type: selectedTargetType, value: targetValue), current: tracker.currentValue)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .card()
                
                HStack(spacing: 12){
                    infoCards[1]
                    InfoCard(title: "Pace", icon: "stopwatch", value: paceString, color: .iceBlue)
                }
                HStack(spacing: 12){
                    InfoCard(title: "Heart Rate", icon: "heart.fill", value: "heartrate", color: .red.mix(with: .white, by: 0.5))
                    InfoCard(title: "Calories", icon: "flame", value: "calorie", color: .electricLime)
                    //TODO: Kalp atışı ve kalori özelliği eklenince burayı güncelle
                }
            }
            
            HStack {
                Button(isPaused ? "Resume": "Pause") {
                    if isPaused { tracker.resume() } else { tracker.pause() }
                }
                .buttonStyle(.neon(foregroundColor: isPaused ? .white:.red, backgroundColor: .coldBlack.mix(with: .white, by: 0.1)))
                
                Button("End") {
                    showEndConfirmation = true
                }
                .buttonStyle(.neon(foregroundColor: .coldBlack, backgroundColor: .electricLime))
                
                .confirmationDialog("Koşuyu bitirmek istiyor musun?",
                                    isPresented: $showEndConfirmation,
                                    titleVisibility: .visible) {
                    Button("End", role: .destructive) {
                        tracker.end()
                        if let session = tracker.makeSession() {
                            modelContext.insert(session)
                        }
                        withAnimation {
                            stage = .ended
                        }
                    }
                    Button("Continue", role: .cancel) { }
                }
            }
        }
    }
    
    @ViewBuilder
    private func endedMenu() -> some View {
        VStack {
            
        }
    }
    
}

//TODO: use stitch for ui design

#Preview {
    CardioView()
}

struct InfoCard: View {
    var title: String
    var icon: String
    var value: String
    var color: Color
    var isMain = false
    var targetText: String?
    var body: some View {
        VStack(alignment: isMain ? .center : .leading) {
            HStack {
                Text("\(title): ")
                    .font(.plusJakartaSans(size: 14))
                    .foregroundStyle(.white)
                if !isMain {
                    Spacer()
                    Image(systemName: icon)
                        .foregroundStyle(color)
                }
            }
            Text(value)
                .font(.spaceGroteskBold(size: isMain ? 36 : 24))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: isMain ? .center : .leading)
        .frame(height: 46)
        .padding()
        .card()
    }
}

struct TargetOption: View {
    @Binding var targetValue: Double
    var type: TargetType
    var isSelected: Bool
    var body: some View {
        VStack {
            HStack {
                Image(systemName: type.systemImage)
                    .font(.system(size: 24))
                    .frame(width: 50, height: 50)
                    .background(
                        .coldBlack.mix(with: .white, by: 0.2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                VStack {
                    Text(type.name)
                        .font(.plusJakartaSans(size: 14))
                }
            }
            .foregroundStyle(isSelected ? .electricLime : .white)
            .frame(maxWidth: .infinity , alignment: .leading)
            .card(brightness: 0.14)
        }
        .padding(2)
        .background(isSelected ? .electricLime : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

struct PickerElement: View {
    @Binding var selected: CardioActivity
    var activity: CardioActivity
    var isSelected: Bool = false
    var body: some View {
        VStack(spacing: 10){
            Image(systemName: activity.systemImage)
                .font(.system(size: 30))
            Text(activity.title)
                .font(.spaceGroteskBold(size: 14))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .foregroundStyle(isSelected ? .coldBlack : .white)
        .padding()
        .background(isSelected ? .electricLime: .coldBlack.mix(with: .white, by: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

struct ProgressBar: View {
    let goal: CardioGoal
    let current: Double
    
    var progress: Double {
        guard goal.value > 0 else { return 0 }
        return min(current / goal.value, 1)
    }
    
    var isGoalReached: Bool { progress >= 1}
    var fractionLength : Int {
        if goal.type == .distance {
            return 1
        } else {
            return 0
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "flag.pattern.checkered")
                .foregroundStyle(isGoalReached ? .electricLime : .iceBlue)
                .font(.system(size: 24))
                .symbolEffect(.bounce, value: isGoalReached)
            Text("\(goal.value.formatted(.number.precision(.fractionLength(fractionLength)))) \(goal.type.unit)")
                .font(.spaceGrotesk(size: 14))
                .foregroundStyle(.white)
            Spacer()
            Text("\(progress.formatted(.percent.precision(.fractionLength(0))))")
                .font(.spaceGrotesk(size: 14))
                .foregroundStyle(.electricLime)
            
        }
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.15))
                Capsule()
                    .fill(.electricLime)
                    .frame(width: geo.size.width * progress)
                    .animation(.easeOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 10)
    }
}
