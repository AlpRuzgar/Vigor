//
//  ExerciseListView.swift
//  Vigor
//
//  Created by Alp Rüzgar on 13.10.2026.
//

import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Workout> { $0.endDate != nil },
           sort: \Workout.startDate, order: .reverse)
    private var workouts: [Workout]
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(workouts) { workout in
                    NavigationLink {
                        ScrollView {
                            WorkoutDetailView(workout: workout)
                                .padding()
                        }
                        .background(.coldBlack)
                    } label: {
                        WorkoutRow(workout: workout)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            delete(workout)
                        }
                    }
                    .contextMenu {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            delete(workout)
                        }
                    }
                }
            }
            .padding()
        }
        .swipeActionsContainerIfAvailable()
        .background(.coldBlack)
    }

    // Egzersizler ve setler cascade kuralıyla birlikte silinir
    private func delete(_ workout: Workout) {
        withAnimation {
            modelContext.delete(workout)
        }
    }
}

struct WorkoutRow: View {
    let workout: Workout

    private var duration: TimeInterval {
        guard let endDate = workout.endDate else { return 0 }
        return endDate.timeIntervalSince(workout.startDate) - workout.pausedDuration
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

    // Egzersiz sırasına göre tekrarsız hedef kaslar
    private var muscles: [TargetMuscle] {
        var seen = Set<TargetMuscle>()
        return workout.entries
            .sorted { $0.orderIndex < $1.orderIndex }
            .flatMap { $0.exercise?.targetMuscles ?? [] }
            .filter { seen.insert($0).inserted }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.electricLime)
                    .frame(width: 44, height: 44)
                    .background(.electricLime.opacity(0.15))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.startDate.formatted(.dateTime.weekday(.wide).day().month()))
                        .font(.plusJakartaSansBold(size: 16))
                        .foregroundStyle(.white)
                    Text(workout.startDate.formatted(date: .omitted, time: .shortened))
                        .font(.spaceGrotesk(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(Duration.seconds(duration).formatted(.units(allowed: [.hours, .minutes], width: .narrow)))
                        .font(.spaceGroteskBold(size: 16))
                        .foregroundStyle(.electricLime)
                    Text("Duration")
                        .font(.spaceGrotesk(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            HStack(spacing: 8) {
                WorkoutStat(value: "\(workout.entries.count)", label: "Exercises")
                WorkoutStat(value: "\(setCount)", label: "Sets")
                WorkoutStat(value: volumeKg.formatted(.number.precision(.fractionLength(0))), label: "kg Volume")
            }

            if !muscles.isEmpty {
                HStack(spacing: 6) {
                    ForEach(muscles.prefix(3), id: \.self) { muscle in
                        MuscleTag(text: muscle.displayName)
                    }
                    if muscles.count > 3 {
                        MuscleTag(text: "+\(muscles.count - 3)")
                    }
                }
            }
        }
        .padding()
        .card()
    }
}

struct WorkoutStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.spaceGroteskBold(size: 18))
                .foregroundStyle(.white)
            Text(label)
                .font(.spaceGrotesk(size: 11))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .card(cornerRadius: 10, brightness: 0.05)
    }
}

struct MuscleTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.spaceGrotesk(size: 12))
            .foregroundStyle(.neonBlue)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.neonBlue.opacity(0.15))
            .clipShape(Capsule())
    }
}
