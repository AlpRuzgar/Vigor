//
//  WorkoutView.swift
//  MyApp
//
//  Created by Alp Rüzgar on 1.10.2026.
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(WorkoutTracker.self) private var tracker
    @Environment(User.self) private var user
    @State private var stage: Stage = .idle
    @State private var isShowingExercisesSheet: Bool = false
    @State private var saveErrorMessage: String?
    @State private var selectedSet: ExerciseSet?
    @State private var shownEntryIndex = 0
    @State private var isCountingDown = false
    @State private var dragOffset: CGFloat = 0
    @State private var cardWidth: CGFloat = 0
    @State private var incomingEdge: Edge = .trailing
    @State private var endedWorkout: Workout?
    // Geri sayım bitince bu şablonla başlatılır; nil ise boş antrenman başlar
    @State private var pendingTemplate: WorkoutTemplate?
    private var shownEntry: WorkoutEntry? {
        tracker.sortedEntries.indices.contains(shownEntryIndex) ? tracker.sortedEntries[shownEntryIndex] : nil
    }
    var title: String {
        switch stage {
        case .idle:
            "Workout"
        case .active:
            "Active"
        case .ended:
            "Summary"
        }
    }
    var body: some View {
        NavigationStack {
            
            ZStack {
                if stage == .active {
                    ActiveBackground(primaryColor: .laserRed)
                        .ignoresSafeArea()
                        .transition(.opacity)
                } else {
                    Color.coldBlack
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
                ScrollView {
                    VStack {
                        switch stage {
                        case .idle:
                            startMenu()
                        case .active:
                            activeMenu()
                        case .ended:
                            endMenu()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .navigationBarTitleDisplayMode(.inline)
                    .customToolbar(title: title)
                    .onAppear {
                        // Yarım kalmış antrenman varsa aktif ekrandan devam et
                        if tracker.isActive { stage = .active }
                    }
                }
            }
        }
        .overlay {
            if isCountingDown {
                CountdownView {
                    // Süre geri sayım bittikten sonra başlar
                    if let pendingTemplate {
                        tracker.startFromTemplate(pendingTemplate)
                    } else {
                        tracker.start()
                    }
                    pendingTemplate = nil
                    withAnimation {
                        isCountingDown = false
                        stage = .active
                    }
                } onCancel: {
                    pendingTemplate = nil
                    withAnimation { isCountingDown = false }
                }
                .transition(.opacity)
            }
        }
    }
    
    @ViewBuilder
    func startMenu() -> some View {
        VStack(spacing: 24) {
            Button("Start Workout") {
                withAnimation {
                    isCountingDown = true
                }
            }
            .buttonStyle(.neon(foregroundColor: .coldBlack, backgroundColor: .electricLime))

            TemplateListView { template in
                pendingTemplate = template
                withAnimation {
                    isCountingDown = true
                }
            }
        }
    }
    
    @ViewBuilder
    func activeMenu() -> some View {
        VStack(spacing: 20) {
            if tracker.sortedEntries.isEmpty{
                // No fixed height: ContentUnavailableView drops the icon when vertically constrained
                ContentUnavailableView {
                    Label("Haven't added any exercises", systemImage: "xmark.circle")
                        .font(.spaceGroteskBold(size: 18))
                        .foregroundStyle(.voltRed)
                } actions: {
                    Button("Add Exercise", systemImage : "plus") {
                        isShowingExercisesSheet.toggle()
                    }
                    .font(.spaceGroteskBold(size: 14))
                    .padding(4)
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(.white)
                    .tint(.voltRed)
                    .padding()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .card()
            }
            else if tracker.sortedEntries.indices.contains(shownEntryIndex) {
                let entry = tracker.sortedEntries[shownEntryIndex]
                
                HStack {
                    Label("\(shownEntryIndex + 1)/\(tracker.sortedEntries.count) Exercises", systemImage: "dumbbell")
                        .font(.spaceGrotesk(size: 16))
                        .foregroundStyle(.electricLime)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.regularGray)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    Spacer()
                    Button("Add Exercise", systemImage: "plus"){
                        isShowingExercisesSheet.toggle()
                    }
                    .font(.spaceGroteskBold(size: 16))
                    .foregroundStyle(.coldBlack)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.iceBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                
                VStack(spacing: 20) {
                    WorkoutEntryCard(entry: entry)
                    VStack(spacing: 8) {
                        ForEach(entry.sets.sorted { $0.orderIndex < $1.orderIndex }) { set in
                            SetRow(entry: entry, set: set, isSelected: selectedSet == set)
                                .onTapGesture {
                                    withAnimation {
                                        selectedSet = set
                                    }
                                }
                                .padding(.horizontal)
                        }
                        
                        Button {
                            tracker.addSet(to: entry)
                            selectedSet = entry.sets.last
                        } label: {
                            // Frame and content shape live inside the label so the whole box is tappable
                            Label("Add Set", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .contentShape(RoundedRectangle(cornerRadius: 15))
                        }
                        .font(.spaceGroteskBold(size: 16))
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundColor(.white)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .padding(.horizontal)
                    }
                                        
                    if let selectedSet {
                        HStack(spacing: 12) {
                            SetStepper(set: selectedSet)
                            WeightStepper(set: selectedSet)
                        }
                        .padding(.horizontal)
                    }
                        
                    
                    HStack (spacing: 80) { // hareketler arası geçiş
                        Button("", systemImage: "chevron.left") { changeEntry(by: -1) }
                            .disabled(shownEntryIndex == 0)
                            .foregroundStyle(.white.mix(with: .black, by: 0.3))
                        Button("", systemImage: "chevron.right") { changeEntry(by: 1) }
                            .disabled(shownEntryIndex >= tracker.sortedEntries.count - 1)
                            .foregroundStyle(.white.mix(with: .black, by: 0.3))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .card()
                // Her hareket ayrı bir görünüm; yeni kart kaydırma yönünün karşı kenarından girer
                .id(entry.id)
                .transition(.asymmetric(insertion: .move(edge: incomingEdge), removal: .identity))
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { cardWidth = $0 }
                .offset(x: dragOffset)
                .contentShape(Rectangle())
                // Yatay kaydırma ile hareketler arası geçiş (dikey kaydırma ScrollView'da kalır)
                .simultaneousGesture(
                    // Kart parmakla birlikte hareket ettiği için global koordinat kullanılır
                    DragGesture(minimumDistance: 20, coordinateSpace: .global)
                        .onChanged { value in
                            let dx = value.translation.width
                            guard abs(dx) > abs(value.translation.height) else { return }
                            let canMove = dx < 0
                                ? shownEntryIndex < tracker.sortedEntries.count - 1
                                : shownEntryIndex > 0
                            // Kenarda gidilecek hareket yoksa lastik gibi direnç göster
                            dragOffset = canMove ? dx : dx / 4
                        }
                        .onEnded { value in
                            let dx = value.translation.width
                            let dy = value.translation.height
                            let isFling = abs(value.predictedEndTranslation.width) > 150
                            if abs(dx) > abs(dy), abs(dx) > 50 || isFling {
                                changeEntry(by: dx < 0 ? 1 : -1)
                            } else {
                                withAnimation(.spring) { dragOffset = 0 }
                            }
                        }
                )
            }
            TimelineView(.periodic(from: .now, by: 1)) { _ in // süre her saniye yenilensin
                HStack {
                    InfoCard(title: "Time", icon: "timer", value: tracker.elapsedString, color: .iceBlue)
                    InfoCard(title: "Heart Rate", icon: "heart.fill", value: "heartrate", color: .red.mix(with: .white, by: 0.5))
                }
            }
            
            Spacer()

            HStack { //durdur / oynat ve bitir butonları
                Button(!tracker.isPaused ? "Pause" : "Resume", systemImage: !tracker.isPaused ? "stop.fill" : "play.fill") {
                    if !tracker.isPaused { tracker.pause() }
                    else { tracker.resume() }
                }
                .buttonStyle(.neon(foregroundColor: .coldBlack, backgroundColor: !tracker.isPaused ? .voltRed : .emerald))

                Button("End Workout") {
                    endWorkout()
                }
                .buttonStyle(.neon(foregroundColor: .coldBlack, backgroundColor: .electricLime))
            }
        }
        .onChange(of: tracker.sortedEntries.count) { _, newCount in
            // Egzersiz silinince index'i geçerli aralıkta tut
            shownEntryIndex = min(shownEntryIndex, max(newCount - 1, 0))
        }
        .sheet(isPresented: $isShowingExercisesSheet) {
            ExercisePickerView { exercises in
                for exercise in exercises {
                    tracker.addExercise(exercise)
                }
            }
        }
        // Gösterilen hareket değişince (kaydırma, ilk ekleme, silme) ilk seti seç
        .onChange(of: shownEntry?.id, initial: true) {
            selectedSet = shownEntry?.sets.min { $0.orderIndex < $1.orderIndex }
        }
        
    }
    
    /// Kartı ekrandan kaydırıp bir sonraki/önceki hareketi karşı kenardan getirir
    private func changeEntry(by step: Int) {
        let newIndex = shownEntryIndex + step
        guard tracker.sortedEntries.indices.contains(newIndex) else {
            withAnimation(.spring) { dragOffset = 0 }
            return
        }
        let distance = cardWidth + 40
        // 1) Mevcut kart kaydırıldığı yönde ekrandan çıkar
        withAnimation(.easeIn(duration: 0.15)) {
            dragOffset = step > 0 ? -distance : distance
        } completion: {
            // 2) Eski kart anında kaldırılır, yeni kart karşı kenardan kayarak gelir
            incomingEdge = step > 0 ? .trailing : .leading
            dragOffset = 0
            withAnimation(.spring(duration: 0.35)) {
                shownEntryIndex = newIndex
            }
        }
    }

    private func endWorkout() {
        // tracker.end() aktif antrenmanı sıfırladığı için özet ekranı için önceden saklanır
        let finished = tracker.workout
        // Hiç egzersiz eklenmediyse antrenman kaydedilmez; özet ekranında bilgilendirme gösterilir
        guard tracker.canEnd else {
            tracker.discard()
            endedWorkout = nil
            withAnimation {
                stage = .ended
            }
            return
        }
        do {
            try tracker.end()
            endedWorkout = finished
            withAnimation {
                stage = .ended
            }
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
    
    @ViewBuilder
    func endMenu() -> some View {
        VStack(spacing: 20) {
            if let endedWorkout {
                WorkoutDetailView(workout: endedWorkout, showsToolbar: false)
            } else {
                unsavedWorkoutNotice()
            }
            Button("Go Back") {
                withAnimation {
                    stage = .idle
                    endedWorkout = nil
                    shownEntryIndex = 0
                }
            }
            .buttonStyle(.neon(foregroundColor: .coldBlack, backgroundColor: .electricLime))
        }
    }

    @ViewBuilder
    private func unsavedWorkoutNotice() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 40))
                .foregroundStyle(.electricLime)
            Text("Workout Not Saved")
                .font(.plusJakartaSansBold(size: 20))
                .foregroundStyle(.white)
            Text("You didn't add any exercises, so this workout wasn't saved!")
                .font(.plusJakartaSans(size: 14))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

/// Aktif antrenman arka planı: coldBlack üzerinde yavaşça dolaşan ve nabız gibi atan primaryColor parıltıları
struct ActiveBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var primaryColor: Color = .laserRed

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            MeshGradient(width: 3, height: 4, points: points(at: t), colors: colors(at: t))
        }
    }
    
    /// Kenar noktaları kenar üzerinde kayar, iç noktalar serbestçe dolaşır; böylece mesh hiç boşluk bırakmaz
    private func points(at t: Double) -> [SIMD2<Float>] {
        func p(_ x: Double, _ y: Double) -> SIMD2<Float> { [Float(x), Float(y)] }
        return [
            p(0, 0), p(0.5 + 0.2 * sin(t * 0.6), 0), p(1, 0),
            p(0, 0.33 + 0.08 * sin(t * 0.8)), p(0.5 + 0.25 * cos(t * 0.5), 0.33 + 0.1 * sin(t * 0.7)), p(1, 0.33 + 0.08 * cos(t * 0.9)),
            p(0, 0.66 + 0.08 * cos(t * 0.7)), p(0.5 + 0.25 * sin(t * 0.4), 0.66 + 0.1 * cos(t * 0.6)), p(1, 0.66 + 0.08 * sin(t * 0.5)),
            p(0, 1), p(0.5 + 0.2 * cos(t * 0.5), 1), p(1, 1)
        ]
    }
    
    /// Renkli noktalar farklı fazlarda parlayıp sönerek nabız etkisi verir
    private func colors(at t: Double) -> [Color] {
        func glow(_ phase: Double, min: Double = 0.35, max: Double = 0.85) -> Color {
            let pulse = (sin(t * 1.2 + phase) + 1) / 2 // 0...1
            return primaryColor.mix(with: .coldBlack, by: max - (max - min) * pulse)
        }
        let black = Color.coldBlack
        return [
            black, glow(0), black,
            black, black, glow(1.5),
            glow(3), black, black,
            black, glow(4.5, min: 0.2, max: 0.7), black
        ]
    }
}

struct WorkoutEntryCard: View {
    @Environment(WorkoutTracker.self) private var tracker
    @Bindable var entry: WorkoutEntry
    @State var isAnimating = false
    var body: some View {
        let b: Color = entry.exercise?.difficulty.colors[0] ?? .coldBlack
        let m: Color = entry.exercise?.difficulty.colors[1] ?? .coldBlack
        let d: Color = entry.exercise?.difficulty.colors[2] ?? .coldBlack
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.exercise?.name ?? "")
                        .font(.plusJakartaSansBold(size: 22))
                        .foregroundStyle(.white)
                    Text(entry.exercise?.targetMuscles.map(\.displayName).joined(separator: ", ") ?? "")
                        .font(.spaceGrotesk(size: 16))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button {
                    tracker.removeEntry(entry)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.voltRed)
                        .font(.system(size: 20))
                        .padding(10)
                        .background(Color.regularGray)
                        .clipShape(Circle())
                }
            }
            .padding()
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            MeshGradient(width: 3, height: 3, points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.1 : 0.8, 0.5], [1.0, isAnimating ? 0.5 : 1],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ], colors: [b, b, m, isAnimating ? d : b, m, d, m, d, d])
            .edgesIgnoringSafeArea(.all)
            .onAppear() {
                withAnimation(.easeInOut(duration: 10.0).repeatForever(autoreverses: true)) {
                    isAnimating.toggle()
                }
            }

        )
    }
}

struct SetStepper: View {
    @Bindable var set: ExerciseSet
    var kind: ExerciseKind {
        self.set.durationSeconds != nil ? .timed : .repetition
    }
    /// Reads/writes whichever field the set uses (durationSeconds for timed, reps for repetition)
    private var value: Double {
        get { self.set.durationSeconds ?? Double(self.set.reps ?? 0) }
        nonmutating set {
            if kind == .timed {
                self.set.durationSeconds = newValue
            } else {
                self.set.reps = Int(newValue)
            }
        }
    }
    @State private var step: Double = 0
    @State private var minValue: Double = 0
    @State private var maxValue: Double = 0
    @State private var unit = ""
    var body: some View {
        ValueStepper(
            value: Binding(get: { value }, set: { value = $0 }),
            step: step,
            range: minValue...maxValue,
            unit: unit
        )
        .onAppear {
            if kind == .repetition {
                step = 1
                minValue = 1
                maxValue = 100
                unit = "REPS"
            } else if kind == .timed {
                step = 15
                minValue = 15
                maxValue = 60 * 10
                unit = "SECONDS"
            }
        }
    }
}

struct WeightStepper: View {
    @Bindable var set: ExerciseSet
    var body: some View {
        ValueStepper(value: $set.weightKg, step: 2.5, range: 0...500, unit: "KG")
    }
}

/// Shared minus/value/plus control used by SetStepper and WeightStepper
struct ValueStepper: View {
    @Binding var value: Double
    let step: Double
    let range: ClosedRange<Double>
    let unit: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(unit)
                .font(.plusJakartaSansBold(size: 12))
                .foregroundStyle(.white)
            HStack {
                Button {
                    value = max(value - step, range.lowerBound)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)
                .disabled(value <= range.lowerBound)
                .background(Color.lightGray)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                
                Text("\(value.formatted())")
                    .font(.spaceGroteskBold(size: 32))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity)
                Button {
                    value = min(value + step, range.upperBound)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)
                .disabled(value >= range.upperBound)
                .background(Color.lightGray)
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
        }
        .padding(12)
        .card(brightness: 0)
    }
}

struct SetRow: View {
    @Environment(WorkoutTracker.self) private var tracker
    @Bindable var entry: WorkoutEntry
    @Bindable var set: ExerciseSet
    
    /// Her egzersizde en az bir set kalmalı
    private var canDelete: Bool { entry.sets.count > 1 }
    
    // Computed from the model so the row re-renders whenever the stepper changes the set
    private var valueString: String {
        if let durationSeconds = self.set.durationSeconds { return durationSeconds.formatted() }
        if let reps = self.set.reps { return "\(reps)" }
        return ""
    }
    private var weightString: String { self.set.weightKg.formatted() }
    private var unit: String {
        self.set.durationSeconds != nil ? "seconds" : "reps"
    }
    let isSelected: Bool
    
    private var textColor: Color { isSelected ? .electricLime : .white }
    
    var body: some View {
        HStack {
            Text("Set \(set.orderIndex + 1)")
                .font(.spaceGroteskBold(size: 16))
                .foregroundStyle(!isSelected ? Color.white.mix(with: .black, by: 0.4) : .electricLime)
                .frame(width: 50, alignment: .center)
            Text("\(valueString) \(unit)")
                .font(.spaceGrotesk(size: 16))
                .foregroundStyle(textColor)
            Image(systemName: "xmark")
                .font(.spaceGroteskBold(size: 16))
                .foregroundStyle(!isSelected ? Color.white.mix(with: .black, by: 0.4) : .electricLime)
                .frame(width: 32, alignment: .center)
            Text("\(weightString) kg")
                .font(.spaceGrotesk(size: 16))
                .foregroundStyle(textColor)
            
            Spacer()
            
            Button {
                tracker.removeSet(set, from: entry)
            } label: {
                Image(systemName: "minus.circle.fill")
                // Son set silinemez; buton grileşerek pasif görünür
                    .foregroundStyle(canDelete ? .voltRed : .gray.opacity(0.5))
                    .font(.system(size: 16))
            }
            .disabled(!canDelete)
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(.coldBlack)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

#Preview {
    let container = try! ModelContainer(for: Workout.self, WorkoutEntry.self, ExerciseSet.self,
                                        WorkoutTemplate.self, TemplateEntry.self, TemplateSet.self,
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return WorkoutView()
        .environment(WorkoutTracker(context: container.mainContext))
        .environment(TemplateManager(context: container.mainContext))
        .modelContainer(container)
}
// TEMP: gradient comparison
#Preview("Gradients") {
    let patterns: [(String, (Color, Color, Color) -> [Color])] = [
        ("A", { b, m, d in [m, m, b, d, m, m, d, d, d] }),
        ("B", { b, m, d in [d, m, b, d, m, b, d, m, b] }),
        ("C", { b, m, d in [b, b, m, b, m, d, m, d, d] }),
        ("D", { b, m, d in [b, m, b, m, d, m, b, m, b] }),
        ("E", { b, m, d in [d, m, m, m, b, m, m, m, d] })
    ]
    ScrollView {
        VStack(spacing: 8) {
            ForEach(patterns, id: \.0) { name, make in
                Text(name).foregroundStyle(.white)
                ForEach(Difficulty.allCases, id: \.self) { diff in
                    let c = diff.colors
                    MeshGradient(width: 3, height: 3, points: [
                        [0, 0], [0.5, 0], [1, 0],
                        [0, 0.5], [0.5, 0.5], [1, 0.5],
                        [0, 1], [0.5, 1], [1, 1]
                    ], colors: make(c[0], c[1], c[2]))
                    .frame(height: 76)
                    .overlay(alignment: .leading) {
                        Text("Bench Press").bold().foregroundStyle(.white).padding()
                    }
                }
            }
        }
        .padding()
    }
    .background(.black)
}

