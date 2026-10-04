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
    var duration: TimeInterval?
    var entry: WorkoutEntry?

    init(orderIndex: Int, reps: Int? = nil, weightKg: Double? = nil, duration: TimeInterval? = nil) {
        self.orderIndex = orderIndex
        self.reps = reps
        self.weightKg = weightKg
        self.duration = duration
    }
}

protocol CardioExercise {
    var duration: TimeInterval { get set }
}

@Model
final class RunSession: CardioExercise {
    var date: Date
    var distanceMeters: Double
    var duration: TimeInterval
    var points: [RoutePoint]

    // Kaydedilmez, sadece okumak için
    var distance: Measurement<UnitLength> {
        Measurement(value: distanceMeters, unit: .meters)
    }

    init(date: Date, distanceMeters: Double, duration: TimeInterval, points: [RoutePoint]) {
        self.date = date
        self.distanceMeters = distanceMeters
        self.duration = duration
        self.points = points
    }
}

struct RoutePoint: Codable, Hashable {
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var timestamp: Date
}
