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
    @Environment(User.self) private var user
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var stage: Stage = .idle
    @State private var isVisible = false
    @State private var showEndConfirmation = false
    @State private var tracker = CardioTracker()
    @State private var endedSession: CardioSession?
    @State private var isCountingDown = false

    @State private var selectedActivity: CardioActivity = .running
    @State private var selectedGoalType: GoalType = .free
    @State private var goalValue: Double = 5
    
    @State private var primaryColor: Color = .neonBlue
    // Hedef kartı en üstte; her seferinde hedef tipinden hesaplanır, böylece önceki seanstan kalan sıra taşınmaz
    private var cardOrder: [Int] {
        switch selectedGoalType {
        case .free, .distance: [0, 1, 2]
        case .duration: [1, 0, 2]
        case .calories: [2, 0, 1]
        }
    }
    
    var infoCards: [InfoCard] {
        let cards = [
            InfoCard(title: "Distance", icon: "ruler", value: distanceString, color: primaryColor),
            InfoCard(title: "Time", icon: "timer", value: elapsedString, color: .white),
            InfoCard(title: "Calories", icon: "flame.fill", value: caloriesString, color: .electricLime)
        ]
        var ordered = cardOrder.map { cards[$0] }
        ordered[0].isMain = true
        ordered[0].goalText = goalString
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
        case .calories:
            return "\(Int(goal.value)) kcal"
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
        return timeString(pace)
    }
    
    // Ortalama tempo (koşu/yürüyüş) ya da ortalama hız (bisiklet)
    private var averageString: String {
        let km = tracker.distance / 1000
        guard km > 0, tracker.elapsed > 0 else { return "--" }
        if tracker.activity.showsPace {
            let pace = Int(tracker.elapsed / km)
            return String(format: "%d:%02d /km", pace / 60, pace % 60)
        }
        return String(format: "%.1f km/h", km / (tracker.elapsed / 3600))
    }
    
    private var caloriesString: String {
        let kcal = user.calories(for: tracker.activity, duration: tracker.elapsed)
        return "\(Int(kcal)) kcal"
    }
    
    // Sadece tam (1 km) lap'ler karşılaştırılır; son yarım lap tempoyu yanıltabilir
    private var fastestLap: Lap? {
        guard tracker.laps.count > 1 else { return nil }
        return tracker.laps
            .filter { $0.distanceMeters >= 1000 }
            .min { $0.duration < $1.duration }
    }
    
    var isPaused: Bool { tracker.state == .paused }
    
    var paceDif: Double {
        guard let last = tracker.laps.last, let currentPace = tracker.currentPace else { return 0 }
        let gap = currentPace - last.pace
        return gap / last.pace
    }
    var paceDifString: String { paceDif.formatted(.percent.precision(.fractionLength(1))) }
    var isFaster: Bool { paceDif > 0 }
    
    private var isLocationUnavailable: Bool {
        switch tracker.lm.authorizationStatus {
        case .denied, .restricted:
            return true
        default:
            return tracker.lm.currentLocation == nil
        }
    }

    var title: String {
        switch stage {
        case .idle:
            "Cardio"
        case .active:
            "Active"
        case .ended:
            "Summary"
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            NavigationStack{
                ScrollView {
                    VStack (spacing: 20){
                        VStack {
                            switch stage {
                            case .idle:
                                startingMenu()
                            case .active:
                                activeMenu()
                            case .ended:
                                if let endedSession {
                                    VStack(spacing: 20) {
                                        CardioDetailsView(cardioSession: endedSession, showsToolbar: false)
                                        Button("Go Back") { goBack() }
                                            .buttonStyle(.neon(foregroundColor: .coldBlack, backgroundColor: primaryColor))
                                    }
                                } else {
                                    unrecordedSessionNotice()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .id("top")
                }
                .background {
                    if stage == .active {
                        ActiveBackground(primaryColor: primaryColor)
                            .ignoresSafeArea()
                            .transition(.opacity)
                    } else {
                        Color.coldBlack
                            .ignoresSafeArea()
                            .transition(.opacity)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .customToolbar(title: title)
            }
            .onChange(of: stage) {
                withAnimation {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
        }
        .scrollClipDisabled()
        .overlay {
            if isCountingDown {
                CountdownView {
                    startCardio()
                } onCancel: {
                    withAnimation { isCountingDown = false }
                }
                .transition(.opacity)
            }
        }

        .onAppear {
            if tracker.lm.authorizationStatus == .notDetermined {
                tracker.lm.requestAuthorization()
            }
            tracker.lm.startUpdatingLocation()
        }
    }
    
    
    // Geri sayım bitince çağrılır: takip (süre + GPS) ancak şimdi başlar
    private func startCardio() {
        tracker.start(activity: selectedActivity, cardioGoal: CardioGoal(type: selectedGoalType, value: goalValue))
        withAnimation(.spring) {
            isCountingDown = false
            stage = .active
        }
    }

    @ViewBuilder
    private func startingMenu() -> some View {
        VStack (spacing: 32) {
            ForecastView(location: tracker.lm.currentLocation)
            
            VStack{
                Text("Aktivite seç")
                    .foregroundStyle(.white)
                    .font(.plusJakartaSans(size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack{
                    ForEach(CardioActivity.allCases, id: \.self) { activity in
                        PickerElement(selected: $selectedActivity, activity: activity, isSelected: selectedActivity == activity)
                            .onTapGesture {
                                withAnimation {
                                    selectedActivity = activity
                                    primaryColor = activity.primaryColor
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
                    ForEach(GoalType.allCases, id: \.self) { type in
                        GoalOption(goalValue: $goalValue ,type: type, isSelected: selectedGoalType == type, primaryColor: primaryColor)
                            .onTapGesture {
                                withAnimation {
                                    selectedGoalType = type
                                    goalValue = selectedGoalType.defaultValue
                                }
                            }
                    }
                }
                .padding(8)
            }
            
            VStack {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(primaryColor)
                    Text("Goal Type: \(selectedGoalType.name)")
                        .font(.plusJakartaSans(size: 16))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                GoalStepper(type: selectedGoalType, value: $goalValue)
            }
            
            
            if isLocationUnavailable {
                HStack(spacing: 8) {
                    Image(systemName: "location.slash.fill")
                        .foregroundStyle(.voltRed)
                    Text("Waiting for GPS signal. Start is disabled until your location is available.")
                        .font(.plusJakartaSans(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button("Start Cardio") {
                withAnimation {
                    isCountingDown = true
                }
            }
            .buttonStyle(.neon(foregroundColor: .coldBlack, backgroundColor: primaryColor))
            .disabled(isLocationUnavailable)
        }
    }

    @ViewBuilder
    private func unrecordedSessionNotice() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 40))
                .foregroundStyle(primaryColor)
            Text("Session Not Recorded")
                .font(.plusJakartaSansBold(size: 20))
                .foregroundStyle(.white)
            Text("We couldn't get any location data for this session!")
                .font(.plusJakartaSans(size: 14))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            Button("Go Back") { goBack() }
                .buttonStyle(.neon(foregroundColor: .coldBlack, backgroundColor: primaryColor))
                .padding(.top, 16)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }

    /// Özet ekranından başlangıç ekranına döner
    private func goBack() {
        // end() GPS'i durdurur; başlangıç ekranı konuma ihtiyaç duyduğu için yeniden başlatılır
        tracker.lm.startUpdatingLocation()
        withAnimation {
            stage = .idle
            endedSession = nil
        }
    }

    @ViewBuilder
    private func activeMenu() -> some View {
        VStack(spacing: 20) {
            Map(position: $cameraPosition) { // harita
                UserAnnotation()
                if tracker.locations.count > 1 {
                    MapPolyline(coordinates: tracker.locations.map(\.coordinate))
                        .stroke(.blue, lineWidth: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            
            TimelineView(.periodic(from: .now, by: 1)) { _ in //statlar
                VStack(spacing: 8) { // hedef belirlenmiş stat
                    infoCards[0]
                    if selectedGoalType != .free {
                        ProgressBar(goal: CardioGoal(type: selectedGoalType, value: goalValue), current: tracker.currentValue(for: user))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .card()
                
                HStack(spacing: 12){ // kalan statlar
                    infoCards[1]
                    InfoCard(title: "Pace", icon: "stopwatch", value: paceString, color: .iceBlue)
                }
                HStack(spacing: 12){
                    InfoCard(title: "Heart Rate", icon: "heart.fill", value: "heartrate", color: .red.mix(with: .white, by: 0.5))
                    infoCards[2]
                    //TODO: Kalp atışı özelliği eklenince burayı güncelle
                }
                
                HStack(spacing: 12) {
                    InfoCard(title: "Last Lap", icon: "", value: tracker.laps.last.map { timeString($0.pace) } ?? "--:-- /km", color: .neonBlue)
                    InfoCard(title: "Pace Diff", icon: "", value: paceDifString, color: isFaster ? primaryColor : .red)
                    
                }
            }
            
            HStack(spacing: 20) { //pause ve end butonları
                Button(isPaused ? "Resume": "Pause") {
                    if isPaused { tracker.resume() } else { tracker.pause() }
                }
                .buttonStyle(.neon(foregroundColor: isPaused ? .white:.red, backgroundColor: .darkGray))
                
                Button("End") {
                    showEndConfirmation = true
                }
                .buttonStyle(.neon(foregroundColor: .coldBlack, backgroundColor: primaryColor))
                
                .confirmationDialog("Koşuyu bitirmek istiyor musun?",
                                    isPresented: $showEndConfirmation,
                                    titleVisibility: .visible) {
                    Button("End", role: .destructive) {
                        tracker.end()
                        if let session = tracker.makeSession() {
                            modelContext.insert(session)
                            endedSession = session
                            switch selectedActivity {
                            case .running:
                                user.runDistance += session.distanceMeters
                            case .walking:
                                user.walkDistance += session.distanceMeters
                            case .cycling:
                                user.cycleDistance += session.distanceMeters
                            }
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
    
}

//TODO: use stitch for ui design

#Preview {
    CardioView()
        .environment(User.preview)
}

extension View {
    func customToolbar(title: String) -> some View {
        self
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.plusJakartaSansBold(size: 24))
                        .foregroundStyle(.electricLime)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)

    }
}



struct LapRow: View {
    let lap: Lap
    var isFastest = false
    
    private var accent: Color { isFastest ? .neonBlue : .electricLime }
    
    private var paceString: String {
        let km = lap.distanceMeters / 1000
        guard km > 0 else { return "--" }
        let pace = Int(lap.duration / km)
        return String(format: "%d:%02d /km", pace / 60, pace % 60)
    }
    
    var body: some View {
        HStack {
            Text("\(lap.index)")
                .font(.spaceGroteskBold(size: 16))
                .foregroundStyle(.coldBlack)
                .frame(width: 32, height: 32)
                .background(accent)
                .clipShape(Circle())
                .neonShadow(isFastest ? .neonBlue : .clear)
            Text(Measurement(value: lap.distanceMeters, unit: UnitLength.meters)
                .formatted(.measurement(width: .abbreviated, usage: .road)))
            .font(.plusJakartaSans(size: 14))
            .foregroundStyle(.white)
            if isFastest {
                Label("Fastest", systemImage: "bolt.fill")
                    .font(.spaceGroteskBold(size: 12))
                    .foregroundStyle(.coldBlack)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.neonBlue)
                    .clipShape(Capsule())
            }
            Spacer()
            Text(paceString)
                .font(.spaceGroteskBold(size: 16))
                .foregroundStyle(isFastest ? .neonBlue : .iceBlue)
        }
        .padding(.vertical, 10)
    }
}



struct GoalOption: View {
    @Binding var goalValue: Double
    var type: GoalType
    var isSelected: Bool
    var primaryColor: Color
    var body: some View {
        VStack {
            HStack {
                Image(systemName: type.systemImage)
                    .font(.system(size: 24))
                    .frame(width: 50, height: 50)
                    .background(
                        Color.regularGray
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                Text(type.name)
                    .font(.plusJakartaSans(size: 14))
                
            }
            .foregroundStyle(isSelected ? primaryColor : .white)
            .frame(maxWidth: .infinity , alignment: .leading)
            .card(brightness: 0.14)
        }
        .padding(2)
        .background(isSelected ? primaryColor : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: isSelected ? primaryColor : .clear ,radius: 10)
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
        .background(isSelected ? activity.primaryColor : .darkGray)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

struct ProgressBar: View {
    let goal: CardioGoal
    let current: Double
    // Bitiş ekranında: yüzde %100'de kesilmez, aşılan miktar gösterilir
    var showsOvershoot = false
    
    var ratio: Double {
        guard goal.value > 0 else { return 0 }
        return current / goal.value
    }
    var progress: Double { min(ratio, 1) }
    var overshoot: Double { max(current - goal.value, 0) }
    
    var overshootString: String {
        switch goal.type {
        case .free:
            return ""
        case .distance: // km
            return "+\(overshoot.formatted(.number.precision(.fractionLength(0...2)))) km"
        case .duration: // dakika
            let s = Int(overshoot * 60)
            return String(format: "+%d:%02d min", s / 60, s % 60)
        case .calories:
            return "+\(Int(overshoot)) kcal"
        }
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
            Text("\((showsOvershoot ? ratio : progress).formatted(.percent.precision(.fractionLength(0))))")
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
        if showsOvershoot && overshoot > 0 {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.right")
                Text("\(overshootString) over goal")
            }
            .font(.spaceGroteskBold(size: 14))
            .foregroundStyle(.electricLime)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
