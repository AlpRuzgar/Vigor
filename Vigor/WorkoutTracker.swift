//
//  WorkoutTracker.swift
//  Vigor
//
//  Created by Alp Rüzgar on 12.10.2026.
//

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class WorkoutTracker {
    private let context: ModelContext
    private(set) var workout: Workout?

    init(context: ModelContext) {
        self.context = context
    }

    var isActive: Bool { workout != nil }
    var isPaused: Bool { workout?.pausedAt != nil }

    var sortedEntries: [WorkoutEntry] {
        (workout?.entries ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    // Geçen süre (duraklamalar hariç): bitmişse bitiş anına, duraklatılmışsa duraklama anına, değilse şu ana kadar
    var elapsed: TimeInterval {
        guard let workout else { return 0 }
        let end = workout.endDate ?? workout.pausedAt ?? .now
        return max(end.timeIntervalSince(workout.startDate) - workout.pausedDuration, 0)
    }

    // Ekranda gösterilecek süre: 1 saatten kısaysa "mm:ss", değilse "h:mm:ss"
    var elapsedString: String {
        let s = Int(elapsed)
        let hours = s / 3600
        let minutes = (s % 3600) / 60
        let seconds = s % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }

    func start() {
        let new = Workout()
        context.insert(new)
        workout = new
    }
    
    /// Şablondaki egzersiz ve setlerin kopyalarıyla yeni antrenman başlatır; şablonun kendisi değişmez
    func startFromTemplate(_ temp: WorkoutTemplate) {
        guard workout == nil else { return }
        let new = Workout()
        context.insert(new)
        for templateEntry in temp.entries.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            // Kütüphaneden silinmiş egzersizler atlanır
            guard let exercise = templateEntry.exercise else { continue }
            let entry = WorkoutEntry(orderIndex: new.entries.count, exercise: exercise)
            let templateSets = templateEntry.sets.sorted { $0.orderIndex < $1.orderIndex }
            if !templateSets.isEmpty {
                // init'in oluşturduğu varsayılan set, şablondaki setlerle değiştirilir
                entry.sets = templateSets.enumerated().map { i, templateSet in
                    let set = ExerciseSet(orderIndex: i, kind: exercise.kind, weightKg: templateSet.weightKg)
                    // Egzersiz türü şablondan sonra değiştiyse kullanılmayan alan nil kalır
                    if set.reps != nil { set.reps = templateSet.reps ?? set.reps }
                    if set.durationSeconds != nil { set.durationSeconds = templateSet.durationSeconds ?? set.durationSeconds }
                    return set
                }
            }
            new.entries.append(entry)
        }
        temp.lastUsed = .now
        workout = new
    }

    
    /// Yarım kalmış antrenmanı geri yükler
    func restoreUnfinished() {
        var descriptor = FetchDescriptor<Workout>(predicate: #Predicate { $0.endDate == nil })
        descriptor.fetchLimit = 1
        if let unfinished = try? context.fetch(descriptor).first {
            workout = unfinished
        }
    }
    
    func pause() {
        guard let workout, workout.pausedAt == nil else { return }
        workout.pausedAt = .now
    }

    func resume() {
        guard let workout, let pausedAt = workout.pausedAt else { return }
        workout.pausedDuration += Date.now.timeIntervalSince(pausedAt)
        workout.pausedAt = nil
    }

    /// Antrenman bitirilebilir mi (en az bir egzersiz eklenmiş olmalı)
    var canEnd: Bool { !sortedEntries.isEmpty }

    func end() throws {
        guard let workout else { return }
        resume()
        workout.endDate = .now
        do {
            try context.save()
        } catch {
            // Kayıt başarısızsa antrenman aktif kalsın ki kullanıcı tekrar deneyebilsin
            workout.endDate = nil
            throw error
        }
        self.workout = nil
        
    }

    /// Egzersiz eklenmemiş antrenmanı kaydetmeden siler (otomatik kayıt yapılmış olabileceği için context'ten de kaldırılır)
    func discard() {
        guard let workout else { return }
        context.delete(workout)
        try? context.save()
        self.workout = nil
    }

    // MARK: - Egzersiz & set
    func addExercise(_ type: ExerciseType) {
        guard let workout else { return }
        let entry = WorkoutEntry(orderIndex: workout.entries.count, exercise: type)
        workout.entries.append(entry)
    }

    func removeEntry(_ entry: WorkoutEntry) {
        guard let workout else { return }
        workout.entries.removeAll { $0 == entry }
        context.delete(entry)
        // Kalan egzersizlerin sırasını boşluk kalmayacak şekilde yeniden numaralandır
        for (i, e) in workout.entries.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated() {
            e.orderIndex = i
        }
    }

    func addSet(to entry: WorkoutEntry) {
        let last = entry.sets.max { $0.orderIndex < $1.orderIndex }
        // Tür, hangi alanın (tekrar/süre) dolu olacağını belirler
        let new = ExerciseSet(orderIndex: entry.sets.count,
                              kind: entry.exercise?.kind ?? .repetition,
                              weightKg: last?.weightKg ?? 0)
        // Önceki set varsa değerleri onunla başlar; kullanılmayan alan nil kalır
        if let last {
            if new.reps != nil { new.reps = last.reps ?? new.reps }
            if new.durationSeconds != nil { new.durationSeconds = last.durationSeconds ?? new.durationSeconds }
        }
        entry.sets.append(new)
    }

    func removeSet(_ set: ExerciseSet, from entry: WorkoutEntry) {
        // Her egzersizde en az bir set kalmalı
        guard entry.sets.count > 1 else { return }
        entry.sets.removeAll { $0 == set }
        context.delete(set)
        for (i, s) in entry.sets.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated() {
            s.orderIndex = i
        }
    }
}
