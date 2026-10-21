//
//  ExerciseLibrary.swift
//  Vigor
//
//  Created by Alp Rüzgar on 4.10.2026.
//

import Foundation

/// Egzersiz kütüphanesi veritabanında saklanmaz; kayıtlar egzersizi adıyla referanslar
enum ExerciseLibrary {
    /// Ada göre sıralı tüm egzersizler
    static let all: [ExerciseType] = definitions
        .map { ExerciseType(name: $0.name, targetMuscles: $0.muscles, kind: $0.kind, difficulty: $0.difficulty) }
        .sorted { $0.name < $1.name }

    private static let byName = Dictionary(all.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })

    static func exercise(named name: String) -> ExerciseType? {
        byName[name]
    }

    // Zorluk seviyeleri free-exercise-db'deki "level" alanından alındı:
    // https://github.com/yuhonas/free-exercise-db
    // beginner → easy, intermediate → medium, expert → hard
    private static let definitions: [(name: String, muscles: [TargetMuscle], kind: ExerciseKind, difficulty: Difficulty)] = [
        // Göğüs
        ("Bench Press", [.chest, .triceps], .repetition, .easy),
        ("Incline Bench Press", [.chest, .shoulders, .triceps], .repetition, .easy),
        ("Decline Bench Press", [.chest, .triceps], .repetition, .easy),
        ("Incline Dumbbell Press", [.chest, .shoulders], .repetition, .easy),
        ("Decline Dumbbell Press", [.chest], .repetition, .easy),
        ("Dumbbell Bench Press", [.chest, .triceps], .repetition, .easy),
        ("Chest Fly", [.chest], .repetition, .easy),
        ("Incline Chest Fly", [.chest, .shoulders], .repetition, .easy),
        ("Cable Crossover", [.chest], .repetition, .easy),
        ("Pec Deck Machine", [.chest], .repetition, .easy),
        ("Push-Up", [.chest, .triceps], .repetition, .easy),
        ("Incline Push-Up", [.chest, .triceps], .repetition, .easy),
        ("Smith Machine Bench Press", [.chest, .triceps], .repetition, .easy),
        // Sırt
        ("Lat Pulldown", [.back, .biceps], .repetition, .easy),
        ("Close-Grip Lat Pulldown", [.back, .biceps], .repetition, .easy),
        ("Straight-Arm Pulldown", [.back], .repetition, .easy),
        ("Barbell Row", [.back, .biceps], .repetition, .easy),
        ("Pendlay Row", [.back, .biceps], .repetition, .medium), // DB'de yok, web kaynaklarına göre
        ("T-Bar Row", [.back, .biceps], .repetition, .easy),
        ("Seated Cable Row", [.back, .biceps], .repetition, .easy),
        ("Single-Arm Dumbbell Row", [.back, .biceps], .repetition, .easy),
        ("Chest-Supported Row", [.back, .biceps], .repetition, .easy),
        ("Pull-Up", [.back, .biceps], .repetition, .easy),
        ("Chin-Up", [.back, .biceps], .repetition, .easy),
        ("Deadlift", [.back, .hamstrings, .glutes], .repetition, .medium),
        ("Sumo Deadlift", [.back, .hamstrings, .glutes, .quads], .repetition, .medium),
        ("Rack Pull", [.back, .hamstrings, .glutes], .repetition, .medium),
        ("Back Extension", [.back, .glutes, .hamstrings], .repetition, .easy),
        ("Good Morning", [.back, .hamstrings, .glutes], .repetition, .medium),
        // Omuz
        ("Overhead Press", [.shoulders, .triceps], .repetition, .easy),
        ("Seated Dumbbell Shoulder Press", [.shoulders, .triceps], .repetition, .easy),
        ("Arnold Press", [.shoulders, .triceps], .repetition, .medium),
        ("Lateral Raise", [.shoulders], .repetition, .easy),
        ("Cable Lateral Raise", [.shoulders], .repetition, .easy),
        ("Front Raise", [.shoulders], .repetition, .easy),
        ("Rear Delt Fly", [.shoulders], .repetition, .easy),
        ("Face Pull", [.shoulders, .back], .repetition, .medium),
        ("Upright Row", [.shoulders, .back], .repetition, .easy),
        ("Barbell Shrug", [.shoulders], .repetition, .easy),
        ("Dumbbell Shrug", [.shoulders], .repetition, .easy),
        // Biseps
        ("Barbell Curl", [.biceps], .repetition, .easy),
        ("Dumbbell Curl", [.biceps], .repetition, .easy),
        ("Hammer Curl", [.biceps, .forearms], .repetition, .easy),
        ("Concentration Curl", [.biceps], .repetition, .easy),
        ("Preacher Curl", [.biceps], .repetition, .easy),
        ("Cable Curl", [.biceps], .repetition, .easy),
        ("Incline Dumbbell Curl", [.biceps], .repetition, .easy),
        ("Spider Curl", [.biceps], .repetition, .easy),
        ("EZ-Bar Curl", [.biceps], .repetition, .easy),
        // Triseps
        ("Triceps Pushdown", [.triceps], .repetition, .easy),
        ("Rope Triceps Pushdown", [.triceps], .repetition, .easy),
        ("Skull Crusher", [.triceps], .repetition, .easy),
        ("Overhead Triceps Extension", [.triceps], .repetition, .easy),
        ("Dips", [.triceps, .chest], .repetition, .easy),
        ("Close-Grip Bench Press", [.triceps, .chest], .repetition, .easy),
        ("Triceps Kickback", [.triceps], .repetition, .easy),
        ("Diamond Push-Up", [.triceps, .chest], .repetition, .medium),
        // Ön kol
        ("Wrist Curl", [.forearms], .repetition, .easy),
        ("Reverse Wrist Curl", [.forearms], .repetition, .easy),
        ("Reverse Curl", [.forearms, .biceps], .repetition, .easy),
        ("Farmer's Carry", [.forearms, .back], .timed, .medium),
        // Karın
        ("Crunch", [.abs], .repetition, .easy),
        ("Cable Crunch", [.abs], .repetition, .easy),
        ("Bicycle Crunch", [.abs], .repetition, .easy),
        ("Sit-Up", [.abs], .repetition, .easy),
        ("Hanging Leg Raise", [.abs], .repetition, .hard),
        ("Lying Leg Raise", [.abs], .repetition, .easy),
        ("Russian Twist", [.abs], .repetition, .medium),
        ("Mountain Climber", [.abs], .timed, .easy),
        ("Plank", [.abs], .timed, .easy),
        ("Side Plank", [.abs], .timed, .easy),
        ("Ab Wheel Rollout", [.abs], .repetition, .medium),
        ("Toe Touch", [.abs], .repetition, .easy),
        // Kalça
        ("Hip Thrust", [.glutes], .repetition, .medium),
        ("Barbell Glute Bridge", [.glutes], .repetition, .medium),
        ("Cable Glute Kickback", [.glutes], .repetition, .medium),
        ("Romanian Deadlift", [.hamstrings, .glutes], .repetition, .medium),
        ("Bulgarian Split Squat", [.quads, .glutes], .repetition, .medium),
        // Ön bacak
        ("Squat", [.quads, .glutes], .repetition, .easy),
        ("Front Squat", [.quads, .glutes], .repetition, .hard),
        ("Hack Squat", [.quads, .glutes], .repetition, .easy),
        ("Goblet Squat", [.quads, .glutes], .repetition, .easy),
        ("Leg Press", [.quads, .glutes], .repetition, .easy),
        ("Leg Extension", [.quads], .repetition, .easy),
        ("Lunge", [.quads, .glutes], .repetition, .easy),
        ("Walking Lunge", [.quads, .glutes], .repetition, .easy),
        ("Step-Up", [.quads, .glutes], .repetition, .medium),
        ("Wall Sit", [.quads], .timed, .easy), // DB'de yok, web kaynaklarına göre
        // Arka bacak
        ("Leg Curl", [.hamstrings], .repetition, .easy),
        ("Stiff-Leg Deadlift", [.hamstrings, .glutes, .back], .repetition, .medium),
        ("Nordic Curl", [.hamstrings], .repetition, .hard), // DB'de yok, web kaynaklarına göre
        ("Glute-Ham Raise", [.hamstrings, .glutes], .repetition, .medium),
        // Kalf
        ("Standing Calf Raise", [.calves], .repetition, .easy),
        ("Seated Calf Raise", [.calves], .repetition, .easy),
        ("Donkey Calf Raise", [.calves], .repetition, .medium),
    ]
}
