//
//  ExerciseSeeder.swift
//  Vigor
//
//  Created by Alp Rüzgar on 4.10.2026.
//

import Foundation
import SwiftData

enum ExerciseSeeder {
    static func seedIfNeeded(_ context: ModelContext) {
        // Veritabanında zaten egzersiz varsa hiçbir şey yapma
        let count = (try? context.fetchCount(FetchDescriptor<ExerciseType>())) ?? 0
        guard count == 0 else { return }

        for item in library {
            context.insert(ExerciseType(name: item.name,
                                        targetMuscles: item.muscles,
                                        kind: item.kind))
        }
    }

    private static let library: [(name: String, muscles: [TargetMuscle], kind: ExerciseKind)] = [
        // Göğüs
        ("Bench Press", [.chest, .triceps], .repetition),
        ("Incline Dumbbell Press", [.chest, .shoulders], .repetition),
        ("Chest Fly", [.chest], .repetition),
        ("Push-Up", [.chest, .triceps], .repetition),
        // Sırt
        ("Lat Pulldown", [.back, .biceps], .repetition),
        ("Barbell Row", [.back], .repetition),
        ("Seated Cable Row", [.back], .repetition),
        ("Pull-Up", [.back, .biceps], .repetition),
        ("Deadlift", [.back, .hamstrings, .glutes], .repetition),
        // Omuz
        ("Overhead Press", [.shoulders, .triceps], .repetition),
        ("Lateral Raise", [.shoulders], .repetition),
        ("Rear Delt Fly", [.shoulders], .repetition),
        ("Face Pull", [.shoulders, .back], .repetition),
        // Biseps
        ("Barbell Curl", [.biceps], .repetition),
        ("Dumbbell Curl", [.biceps], .repetition),
        ("Hammer Curl", [.biceps, .forearms], .repetition),
        // Triseps
        ("Triceps Pushdown", [.triceps], .repetition),
        ("Skull Crusher", [.triceps], .repetition),
        ("Overhead Triceps Extension", [.triceps], .repetition),
        ("Dips", [.triceps, .chest], .repetition),
        // Ön kol
        ("Wrist Curl", [.forearms], .repetition),
        // Karın
        ("Crunch", [.abs], .repetition),
        ("Hanging Leg Raise", [.abs], .repetition),
        ("Russian Twist", [.abs], .repetition),
        ("Plank", [.abs], .timed),
        ("Side Plank", [.abs], .timed),
        // Kalça
        ("Hip Thrust", [.glutes], .repetition),
        ("Romanian Deadlift", [.hamstrings, .glutes], .repetition),
        // Ön bacak
        ("Squat", [.quads, .glutes], .repetition),
        ("Leg Press", [.quads, .glutes], .repetition),
        ("Leg Extension", [.quads], .repetition),
        ("Lunge", [.quads, .glutes], .repetition),
        ("Wall Sit", [.quads], .timed),
        // Arka bacak
        ("Leg Curl", [.hamstrings], .repetition),
        // Kalf
        ("Standing Calf Raise", [.calves], .repetition),
        ("Seated Calf Raise", [.calves], .repetition),
    ]
}
