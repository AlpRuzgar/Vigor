//
//  WorkoutDetailView.swift
//  Vigor
//
//  Created by Alp Rüzgar on 16.10.2026.
//

import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Environment(TemplateManager.self) private var templateManager
    let workout: Workout
    var showsToolbar: Bool = true
    @State private var isNamingTemplate = false
    @State private var templateName = ""
    @State private var isSavedAsTemplate = false

    // Şablon için önerilen isim: egzersiz sırasına göre ilk iki hedef kas (ör. "Chest · Triceps")
    private var suggestedTemplateName: String {
        var seen = Set<TargetMuscle>()
        let muscles = sortedEntries
            .flatMap { $0.exercise?.targetMuscles ?? [] }
            .filter { seen.insert($0).inserted }
        return muscles.isEmpty ? "My Workout" : muscles.prefix(2).map { $0.displayName }.joined(separator: " · ")
    }

    private var sortedEntries: [WorkoutEntry] {
        workout.entries.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var duration: TimeInterval {
        guard let endDate = workout.endDate else { return 0 }
        return max(endDate.timeIntervalSince(workout.startDate) - workout.pausedDuration, 0)
    }

    // 1 saatten kısaysa "mm:ss", değilse "h:mm:ss"
    private var durationString: String {
        let s = Int(duration)
        let hours = s / 3600
        let minutes = (s % 3600) / 60
        let seconds = s % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }

    private var setCount: Int {
        workout.entries.reduce(0) { $0 + $1.sets.count }
    }

    // Toplam hacim: tekrarlı setlerde tekrar × kilo
    private var volumeKg: Double {
        workout.entries
            .flatMap(\.sets)
            .reduce(0) { $0 + Double($1.reps ?? 0) * $1.weightKg }
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.plusJakartaSansBold(size: 20))
                    .neonShadow(.electricLime)
                Text("Workout")
                    .font(.plusJakartaSansBold(size: 32))
                    .neonShadow(.electricLime)
                Spacer()
                Button {
                    templateName = suggestedTemplateName
                    isNamingTemplate = true
                } label: {
                    Image(systemName: isSavedAsTemplate ? "star.fill" : "star")
                        .font(.system(size: 20))
                        .padding(10)
                        .background(Color.regularGray)
                        .clipShape(Circle())
                        .contentTransition(.symbolEffect(.replace))
                }
                // Aynı ekrandan tekrar tekrar kopya oluşturulmasın
                .disabled(isSavedAsTemplate || sortedEntries.isEmpty)
                .accessibilityLabel(isSavedAsTemplate ? "Saved as template" : "Save as template")
            }
            .foregroundStyle(.electricLime)
            .alert("Save as Template", isPresented: $isNamingTemplate) {
                TextField("Template name", text: $templateName)
                Button("Cancel", role: .cancel) { }
                Button("Save") { saveTemplate() }
            } message: {
                Text("Quick start this workout later from the Workout tab.")
            }

            Text(workout.startDate.formatted(date: .abbreviated, time: .shortened))
                .font(.spaceGrotesk(size: 14))
                .foregroundStyle(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)

            InfoCard(title: "Time", icon: "timer", value: durationString, color: .electricLime, isMain: true)

            HStack(spacing: 12) {
                InfoCard(title: "Exercises", icon: "dumbbell", value: "\(workout.entries.count)", color: .white)
                InfoCard(title: "Sets", icon: "repeat", value: "\(setCount)", color: .white)
            }
            InfoCard(title: "Volume", icon: "scalemass",
                     value: "\(volumeKg.formatted(.number.precision(.fractionLength(0)))) kg",
                     color: .iceBlue)

            if !sortedEntries.isEmpty {
                VStack(spacing: 12) {
                    Text("Exercises")
                        .font(.plusJakartaSans(size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(sortedEntries) { entry in
                        WorkoutEntrySummary(entry: entry)
                    }
                }
            }
        }
        .modifier(WorkoutDetailToolbarModifier(isEnabled: showsToolbar))
    }

    private func saveTemplate() {
        let name = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
        templateManager.createTemplateFromWorkout(workout, name: name.isEmpty ? suggestedTemplateName : name)
        withAnimation { isSavedAsTemplate = true }
    }
}

/// Bitmiş bir egzersizin setlerini listeler; en yüksek (tekrar/süre × kilo) seti vurgular
struct WorkoutEntrySummary: View {
    let entry: WorkoutEntry

    private var sortedSets: [ExerciseSet] {
        entry.sets.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// Setin tekrar (veya süre) değeri
    private func amount(_ set: ExerciseSet) -> Double {
        set.durationSeconds ?? Double(set.reps ?? 0)
    }

    /// Tekrar/süre × kilo en büyük olan set; kilo yoksa (vücut ağırlığı) tekrar/süre eşitliği bozar
    private var bestSet: ExerciseSet? {
        sortedSets.max { lhs, rhs in
            let l = amount(lhs) * lhs.weightKg
            let r = amount(rhs) * rhs.weightKg
            return l != r ? l < r : amount(lhs) < amount(rhs)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.exercise?.name ?? "")
                        .font(.plusJakartaSansBold(size: 18))
                        .foregroundStyle(.white)
                    Text(entry.exercise?.targetMuscles.map(\.displayName).joined(separator: ", ") ?? "")
                        .font(.spaceGrotesk(size: 13))
                        .foregroundStyle(.neonBlue)
                }
                Spacer()
                if let difficulty = entry.exercise?.difficulty {
                    DifficultyBadge(difficulty: difficulty)
                }
            }

            VStack(spacing: 8) {
                ForEach(sortedSets) { set in
                    CompletedSetRow(set: set, isBest: set == bestSet)
                }
            }
        }
        .padding()
        .card()
    }
}

/// Salt okunur set satırı (SetRow'un düzenleme kontrolleri olmadan)
struct CompletedSetRow: View {
    let set: ExerciseSet
    let isBest: Bool

    private var valueString: String {
        if let durationSeconds = set.durationSeconds { return "\(durationSeconds.formatted()) seconds" }
        if let reps = set.reps { return "\(reps) reps" }
        return ""
    }

    private var accent: Color { isBest ? .electricLime : .white }
    private var secondary: Color { isBest ? .electricLime : Color.white.mix(with: .black, by: 0.4) }

    var body: some View {
        HStack {
            Text("Set \(set.orderIndex + 1)")
                .font(.spaceGroteskBold(size: 16))
                .foregroundStyle(secondary)
                .frame(width: 50, alignment: .center)
            Text(valueString)
                .font(.spaceGrotesk(size: 16))
                .foregroundStyle(accent)
            Image(systemName: "xmark")
                .font(.spaceGroteskBold(size: 16))
                .foregroundStyle(secondary)
                .frame(width: 32, alignment: .center)
            Text("\(set.weightKg.formatted()) kg")
                .font(.spaceGrotesk(size: 16))
                .foregroundStyle(accent)
            Spacer()
            if isBest {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.electricLime)
                    .neonShadow(.electricLime)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(.coldBlack)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay {
            if isBest {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(.electricLime, lineWidth: 1.5)
            }
        }
    }
}

private struct WorkoutDetailToolbarModifier: ViewModifier {
    var isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .navigationBarTitleDisplayMode(.inline)
                .customToolbar(title: "Workout")
        } else {
            content
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Workout.self, WorkoutEntry.self, ExerciseSet.self,
                                        WorkoutTemplate.self, TemplateEntry.self, TemplateSet.self,
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let bench = ExerciseType(name: "Bench Press", targetMuscles: [.chest, .triceps], difficulty: .hard)
    let plank = ExerciseType(name: "Plank", targetMuscles: [.abs], kind: .timed, difficulty: .easy)
    let workout = Workout(startDate: .now.addingTimeInterval(-3600))
    workout.endDate = .now
    container.mainContext.insert(workout)
    let benchEntry = WorkoutEntry(orderIndex: 0, exercise: bench)
    let plankEntry = WorkoutEntry(orderIndex: 1, exercise: plank)
    workout.entries = [benchEntry, plankEntry]
    benchEntry.sets[0].reps = 10
    benchEntry.sets[0].weightKg = 60
    let heavy = ExerciseSet(orderIndex: 1, kind: .repetition, weightKg: 80)
    heavy.reps = 8
    benchEntry.sets.append(heavy)
    return ScrollView {
        WorkoutDetailView(workout: workout)
            .padding()
    }
    .background(.coldBlack)
    .environment(TemplateManager(context: container.mainContext))
    .modelContainer(container)
}
