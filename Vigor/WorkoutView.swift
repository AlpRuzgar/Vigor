//
//  WorkoutView.swift
//  MyApp
//
//  Created by Alp Rüzgar on 1.10.2026.
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<Workout> { $0.endDate == nil })
    private var activeWorkouts: [Workout]
    
    @State private var stage: Stage = .idle
    @State private var finishedWorkout: Workout?
    @State private var showPicker = false
    @State private var showFinishConfirmation = false
    
    var body: some View {
        NavigationStack {
            switch stage {
            case .idle:
                startingMenu()
            case .runStarted:
                activeMenu()
            case .runEnded:
                endingMenu()
            }
        }
        .onAppear {
            // Uygulama kapanıp açıldıysa yarım kalan antrenmana dön
            if stage == .idle, activeWorkouts.first != nil {
                stage = .runStarted
            }
        }
        .sheet(isPresented: $showPicker) {
            ExercisePickerView { exercise in
                guard let workout = activeWorkouts.first else { return }
                let entry = WorkoutEntry(orderIndex: workout.entries.count,
                                         exercise: exercise)
                workout.entries.append(entry)
            }
        }
    }

    
    @ViewBuilder
    private func startingMenu() -> some View {
        Button("Antrenmana Başla") {
            modelContext.insert(Workout())
            withAnimation(.spring) {
                stage = .runStarted
            }
        }
        .buttonStyle(.borderedProminent)
    }
    
    @ViewBuilder
    private func activeMenu() -> some View {
        if let workout = activeWorkouts.first {
            List {
                ForEach(workout.entries.sorted { $0.orderIndex < $1.orderIndex }) { entry in
                    WorkoutEntrySection(entry: entry)
                }
                
                Button("Egzersiz Ekle", systemImage: "plus") {
                    showPicker = true
                }

                Button("Bitir", role: .destructive) {
                    showFinishConfirmation = true
                }
                .confirmationDialog("Antrenmanı bitirmek istiyor musun?",
                                    isPresented: $showFinishConfirmation,
                                    titleVisibility: .visible) {
                    Button("Bitir", role: .destructive) {
                        workout.endDate = .now
                        finishedWorkout = workout
                        withAnimation {
                            stage = .runEnded
                        }
                    }
                    Button("Devam et", role: .cancel) { }
                }
            }
        }
    }
    
    @ViewBuilder
    private func endingMenu() -> some View {
        VStack(spacing: 16) {
            if let workout = finishedWorkout, let end = workout.endDate {
                Text(Duration.seconds(end.timeIntervalSince(workout.startDate))
                    .formatted(.time(pattern: .hourMinuteSecond)))
                    .font(.largeTitle.bold())
                Text("\(workout.entries.count) egzersiz")
            }

            Button("Yeni Antrenman") {
                finishedWorkout = nil
                withAnimation {
                    stage = .idle
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct WorkoutEntrySection: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var entry: WorkoutEntry

    private var sortedSets: [ExerciseSet] {
        entry.sets.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        Section(entry.exercise?.name ?? "—") {
            ForEach(Array(sortedSets.enumerated()), id: \.element.id) { index, set in
                SetRow(set: set,
                       kind: entry.exercise?.kind ?? .repetition,
                       number: index + 1)
            }
            .onDelete { offsets in
                let sets = sortedSets
                for i in offsets { modelContext.delete(sets[i]) }
            }

            Button("Set Ekle", systemImage: "plus") {
                addSet()
            }
        }
    }

    private func addSet() {
        let next = (entry.sets.map(\.orderIndex).max() ?? -1) + 1
        let last = sortedSets.last
        // Önceki setin değerlerini kopyala
        let newSet = ExerciseSet(orderIndex: next,
                                 reps: last?.reps,
                                 weightKg: last?.weightKg,
                                 duration: last?.duration)
        entry.sets.append(newSet)
    }
}

private struct SetRow: View {
    @Bindable var set: ExerciseSet
    let kind: ExerciseKind
    let number: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .foregroundStyle(.secondary)
                .frame(width: 24)

            switch kind {
            case .repetition:
                TextField("Kg", value: $set.weightKg, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Tekrar", value: $set.reps, format: .number)
                    .keyboardType(.numberPad)
            case .timed:
                TextField("Süre (sn)", value: $set.duration, format: .number)
                    .keyboardType(.numberPad)
            }
        }
        .textFieldStyle(.roundedBorder)
        .multilineTextAlignment(.center)
    }
}

#Preview {
    WorkoutView()
}
