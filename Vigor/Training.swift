//
//  Training.swift
//  MyApp
//
//  Created by Alp Rüzgar on 1.10.2026.
//

import Foundation
import SwiftData

enum TargetMuscle {
    case back
    case chest
}


protocol WorkoutComponent {
    var name: String { get set }
    var orderIndex: Int { get set }
}
    
struct Rest: WorkoutComponent {
    var name: String = "Rest"
    var orderIndex: Int
}

protocol Exercise: WorkoutComponent {
    var targetMuscles: [TargetMuscle] { get set }
}

struct RepetitionExercise: Exercise {
    var targetMuscles: [TargetMuscle]
    var name: String
    var orderIndex: Int
    
    var sets: Int
    var reps: Int
    var weight: Measurement<UnitMass>
}

struct TimeBasedExercise: Exercise {
    var targetMuscles: [TargetMuscle]
    var name: String
    var orderIndex: Int
    
    var time: TimeInterval
    var weight: Measurement<UnitMass>? //For weighted time based exercises 
}

struct Workout {
    var date: Date
    var exercises: [any WorkoutComponent]
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
