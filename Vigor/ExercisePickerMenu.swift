//
//  ExercisePickerMenu.swift
//  Vigor
//
//  Created by Alp Rüzgar on 4.10.2026.
//

import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExerciseType.name) private var exercises: [ExerciseType]
    @State private var searchText = ""

    let onSelect: (ExerciseType) -> Void

    private var filtered: [ExerciseType] {
        searchText.isEmpty
            ? exercises
            : exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { exercise in
                Button {
                    onSelect(exercise)
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(exercise.name)
                        Text(exercise.targetMuscles.map { $0.rawValue.capitalized }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.neonBlue)
                    }
                }
                .foregroundStyle(.primary)
            }
            .searchable(text: $searchText)
            .navigationTitle("Egzersiz Seç")
            .toolbar {
                Button("Kapat") { dismiss() }
            }
        }
    }
}
