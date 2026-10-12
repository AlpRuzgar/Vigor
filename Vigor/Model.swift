//
//  Training.swift
//  MyApp
//
//  Created by Alp Rüzgar on 1.10.2026.
//

import Foundation
import SwiftData

enum TargetMuscle: String, Codable, CaseIterable {
    case chest, back, shoulders, biceps, triceps, forearms
    case abs, glutes, quads, hamstrings, calves
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
    var arrayIndex: Int {
        switch self {
        case .free:
            -1
        case .distance:
            0
        case .duration:
            1
        case .calories:
            2
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

// Kütüphanedeki egzersiz tanımı
@Model
final class ExerciseType {
    var name: String
    var targetMuscles: [TargetMuscle]
    var kind: ExerciseKind
    
    init(name: String, targetMuscles: [TargetMuscle], kind: ExerciseKind = .repetition) {
        self.name = name
        self.targetMuscles = targetMuscles
        self.kind = kind
    }
}

// Bir antrenman
@Model
final class Workout {
    var startDate: Date
    var endDate: Date?
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutEntry.workout)
    var entries: [WorkoutEntry] = []
    
    init(startDate: Date = .now) {
        self.startDate = startDate
    }
}

// Antrenmandaki bir egzersiz kaydı
@Model
final class WorkoutEntry {
    var orderIndex: Int
    var workout: Workout?
    var exercise: ExerciseType?
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.entry)
    var sets: [ExerciseSet] = []
    
    init(orderIndex: Int, exercise: ExerciseType) {
        self.orderIndex = orderIndex
        self.exercise = exercise
    }
}

// Tek bir set
@Model
final class ExerciseSet {
    var orderIndex: Int
    var reps: Int?
    var weightKg: Double?
    var entry: WorkoutEntry?
    
    init(orderIndex: Int, reps: Int? = nil, weightKg: Double? = nil) {
        self.orderIndex = orderIndex
        self.reps = reps
        self.weightKg = weightKg
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
    var pace: TimeInterval { (duration / 60) / (distanceMeters * 1000) }
}
