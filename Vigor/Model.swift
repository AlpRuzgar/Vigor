//
//  Training.swift
//  MyApp
//
//  Created by Alp Rüzgar on 1.10.2026.
//

import Foundation
import SwiftData
import SwiftUI

enum Difficulty: String, Codable, CaseIterable {
    case easy, medium, hard

    var colors: [Color] {
        switch self {
        case .easy: [.brightTeal, .emerald, .darkForest]
        case .medium: [ .neonLemon, .amber, .charredYellow]
        case .hard: [ .plasmaOrange, .laserRed, .darkCrimson]
        }
    }
}

enum TargetMuscle: String, Codable, CaseIterable {
    case chest, back, shoulders, biceps, triceps, forearms
    case abs, glutes, quads, hamstrings, calves

    var displayName: String { rawValue.capitalized }
}

enum ExerciseKind: String, Codable {
    case repetition // tekrar + kilo
    case timed      // süre (+ opsiyonel kilo)
}

enum CardioActivity: String, Codable, CaseIterable {
    case running, walking, cycling
    
    var title: String {
        switch self {
        case .running: "Koşu"
        case .walking: "Yürüyüş"
        case .cycling: "Bisiklet"
        }
    }
    
    var systemImage: String {
        switch self {
        case .running: "figure.run"
        case .walking: "figure.walk"
        case .cycling: "figure.outdoor.cycle"
        }
    }
    
    // Bisiklette pace yerine km/h gösterilir
    var showsPace: Bool { self != .cycling }

    // Ortalama tempo için yaklaşık MET değerleri
    var met: Double {
        switch self {
        case .running: 9.8
        case .walking: 3.5
        case .cycling: 7.5
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .running:
                .neonBlue
        case .walking:
                .plasmaOrange
        case .cycling:
                .neonPurple
        }
    }
}

enum GoalType: String, Codable, CaseIterable {
    case free, distance, duration, calories

    var name: String {
        switch self {
        case .free:
            "Free"
        case .distance:
            "Distance"
        case .duration:
            "Time"
        case .calories:
            "Calories"
        }
    }

    var systemImage: String {
        switch self {
        case .free:
            "infinity"
        case .distance:
            "ruler"
        case .duration:
            "timer"
        case .calories:
            "flame.fill"
        }
    }
    var unit: String {
        switch self {
        case .free: ""
        case .distance: "km"
        case .duration: "min"
        case .calories: "kcal"
        }
    }
    var range: ClosedRange<Double> {
        switch self {
        case .free: 0...0
        case .distance: 1...42
        case .duration: 5...180
        case .calories: 50...1500
        }
    }
    var step: Double {
        switch self {
        case .free: 0
        case .distance: 0.5
        case .duration: 5
        case .calories: 50
        }
    }
    var defaultValue: Double { range.lowerBound * 5}
}


struct CardioGoal {
    var type: GoalType
    var value: Double
}

// Kütüphanedeki egzersiz tanımı; veritabanında saklanmaz, ExerciseLibrary'den gelir
struct ExerciseType: Hashable, Identifiable {
    let name: String
    let targetMuscles: [TargetMuscle]
    let kind: ExerciseKind
    let difficulty: Difficulty

    var id: String { name }

    init(name: String, targetMuscles: [TargetMuscle], kind: ExerciseKind = .repetition, difficulty: Difficulty = .medium) {
        self.name = name
        self.targetMuscles = targetMuscles
        self.kind = kind
        self.difficulty = difficulty
    }
}

// Bir antrenman
@Model
final class Workout {
    var startDate: Date
    var endDate: Date?
    var pausedAt: Date?
    var pausedDuration: TimeInterval = 0
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutEntry.workout)
    var entries: [WorkoutEntry] = []
    
    init(startDate: Date = .now) {
        self.startDate = startDate
    }
}

// Favori antrenman şablonu; geçmiş antrenmanlardan bağımsız, kendi egzersiz ve set kopyalarını tutar
@Model
final class WorkoutTemplate {
    var name: String
    var createdAt: Date
    var lastUsed: Date?

    @Relationship(deleteRule: .cascade, inverse: \TemplateEntry.template)
    var entries: [TemplateEntry] = []

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }
}

// Şablondaki bir egzersiz
@Model
final class TemplateEntry {
    var orderIndex: Int
    var template: WorkoutTemplate?
    // Egzersiz kütüphanede adıyla aranır
    var exerciseName: String = ""
    var exercise: ExerciseType? { ExerciseLibrary.exercise(named: exerciseName) }

    @Relationship(deleteRule: .cascade, inverse: \TemplateSet.entry)
    var sets: [TemplateSet] = []

    init(orderIndex: Int, exercise: ExerciseType?) {
        self.orderIndex = orderIndex
        self.exerciseName = exercise?.name ?? ""
    }
}

// Şablondaki bir set
@Model
final class TemplateSet {
    var orderIndex: Int
    var reps: Int?
    var durationSeconds: TimeInterval?
    var weightKg: Double = 0.0
    var entry: TemplateEntry?

    init(orderIndex: Int, reps: Int?, durationSeconds: TimeInterval?, weightKg: Double) {
        self.orderIndex = orderIndex
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.weightKg = weightKg
    }
}

// Antrenmandaki bir egzersiz kaydı
@Model
final class WorkoutEntry {
    var orderIndex: Int
    var workout: Workout?
    // Egzersiz kütüphanede adıyla aranır
    var exerciseName: String = ""
    var exercise: ExerciseType? { ExerciseLibrary.exercise(named: exerciseName) }
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.entry)
    var sets: [ExerciseSet] = []

    init(orderIndex: Int, exercise: ExerciseType) {
        self.orderIndex = orderIndex
        self.exerciseName = exercise.name
        // İlk set egzersizin türüne göre oluşturulur
        self.sets = [ExerciseSet(orderIndex: 0, kind: exercise.kind)]
    }
}

// Tek bir set
@Model
final class ExerciseSet {
    var orderIndex: Int
    var reps: Int? //tekrarlı egzersizler için
    var durationSeconds: TimeInterval? //süre tutularak yapılan egzersizler için
    var weightKg: Double = 0.0
    var entry: WorkoutEntry?

    /// Egzersiz türü hangi alanın kullanılacağını belirler; diğer alan nil kalır
    init(orderIndex: Int, kind: ExerciseKind, weightKg: Double = 0) {
        self.orderIndex = orderIndex
        self.weightKg = weightKg
        switch kind {
        case .repetition:
            self.reps = 1
            self.durationSeconds = nil
        case .timed:
            self.reps = nil
            self.durationSeconds = 15
        }
    }
}

protocol CardioExercise {
    var duration: TimeInterval { get set }
}

@Model
final class CardioSession: CardioExercise {
    var activity: CardioActivity = CardioActivity.running
    var date: Date
    var distanceMeters: Double
    var duration: TimeInterval
    var points: [RoutePoint]
    var laps: [Lap] = []
    
    // Kaydedilmez, sadece okumak için
    var distance: Measurement<UnitLength> {
        Measurement(value: distanceMeters, unit: .meters)
    }
    init(activity: CardioActivity, date: Date, distanceMeters: Double,
         duration: TimeInterval, points: [RoutePoint], laps: [Lap] = []) {
        self.activity = activity
        self.date = date
        self.distanceMeters = distanceMeters
        self.duration = duration
        self.points = points
        self.laps = laps
    }
    
    var goalType: GoalType = GoalType.free
    var goalValue: Double?
    var goalInterval: TimeInterval?
}

struct RoutePoint: Codable, Hashable {
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var timestamp: Date
}

struct Lap: Codable, Hashable {
    var index: Int
    var distanceMeters: Double
    var duration: TimeInterval
    var pace: TimeInterval { (duration / 60) / (distanceMeters / 1000) } // dk/km
}
