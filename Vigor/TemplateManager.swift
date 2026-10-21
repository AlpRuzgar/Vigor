//
//  TemplateManager.swift
//  Vigor
//
//  Created by Alp Rüzgar on 21.10.2026.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class TemplateManager {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    /// Egzersizler ve setler kopyalanır; böylece antrenman silinse ya da düzenlense de şablon etkilenmez
    func createTemplate(_ name: String, from entries: [WorkoutEntry]) {
        let template = WorkoutTemplate(name: name)
        context.insert(template)
        // Sıra numaraları boşluk kalmayacak şekilde yeniden verilir
        for (i, entry) in entries.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated() {
            let copy = TemplateEntry(orderIndex: i, exercise: entry.exercise)
            copy.sets = entry.sets
                .sorted { $0.orderIndex < $1.orderIndex }
                .enumerated()
                .map { j, set in
                    TemplateSet(orderIndex: j, reps: set.reps,
                                durationSeconds: set.durationSeconds, weightKg: set.weightKg)
                }
            template.entries.append(copy)
        }
    }

    func createTemplateFromWorkout(_ workout: Workout, name: String) {
        createTemplate(name, from: workout.entries)
    }
    
    func deleteTemplate(_ temp: WorkoutTemplate) {
        context.delete(temp)
    }
}
