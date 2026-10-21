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
    private let exercises = ExerciseLibrary.all
    @State private var searchText = ""
    // Seçim sırasını korumak için dizi kullanılıyor
    @State private var selected: [ExerciseType] = []

    let onAdd: ([ExerciseType]) -> Void

    private var filtered: [ExerciseType] {
        searchText.isEmpty
            ? exercises
            : exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if filtered.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                            .foregroundStyle(.white)
                            .card()
                    } else {
                        ForEach(filtered) { exercise in
                            ExercisePickerRow(exercise: exercise,
                                              selectionNumber: selected.firstIndex(of: exercise).map { $0 + 1 })
                                .contentShape(RoundedRectangle(cornerRadius: 15))
                                .onTapGesture {
                                    withAnimation(.snappy) { toggle(exercise) }
                                }
                        }
                    }
                }
                .padding()
            }
            .background(.coldBlack)
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationBarTitleDisplayMode(.inline)
            .customToolbar(title: "Exercises")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(selected.isEmpty ? "Add" : "Add (\(selected.count))") {
                    onAdd(selected)
                    dismiss()
                }
                .buttonStyle(.neon(foregroundColor: .coldBlack,
                                   backgroundColor: selected.isEmpty ? .regularGray : .electricLime))
                .disabled(selected.isEmpty)
                .padding()
            }
        }
    }

    private func toggle(_ exercise: ExerciseType) {
        if let index = selected.firstIndex(of: exercise) {
            selected.remove(at: index)
        } else {
            selected.append(exercise)
        }
    }
}

struct ExercisePickerRow: View {
    var exercise: ExerciseType
    /// Seçildiyse eklenme sırası (1'den başlar), seçilmediyse nil
    var selectionNumber: Int?

    private var isSelected: Bool { selectionNumber != nil }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.kind == .timed ? "timer" : "dumbbell.fill")
                .font(.system(size: 18))
                .foregroundStyle(.electricLime)
                .frame(width: 44, height: 44)
                .background(.electricLime.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.plusJakartaSansBold(size: 16))
                    .foregroundStyle(.white)
                Text(exercise.targetMuscles.map(\.displayName).joined(separator: ", "))
                    .font(.spaceGrotesk(size: 13))
                    .foregroundStyle(.neonBlue)
                DifficultyBadge(difficulty: exercise.difficulty)
            }

            Spacer()

            // Seçim sırası numara olarak gösterilir; eklenecek sıra ile aynıdır
            ZStack {
                Circle()
                    .stroke(isSelected ? Color.electricLime : .white.opacity(0.3), lineWidth: 2)
                if let selectionNumber {
                    Circle().fill(.electricLime)
                    Text("\(selectionNumber)")
                        .font(.spaceGroteskBold(size: 14))
                        .foregroundStyle(.coldBlack)
                }
            }
            .frame(width: 26, height: 26)
        }
        .padding()
        .card()
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(isSelected ? Color.electricLime : .clear, lineWidth: 1.5)
        }
    }
}

/// Zorluk seviyesini, seviyenin renkleriyle küçük bir etiket olarak gösterir
struct DifficultyBadge: View {
    let difficulty: Difficulty

    var body: some View {
        let color = difficulty.colors[0]
        HStack(spacing: 4) {
            // Seviye arttıkça dolu çubuk sayısı artar
            HStack(spacing: 2) {
                ForEach(Difficulty.allCases.indices, id: \.self) { i in
                    Capsule()
                        .fill(i <= level ? color : .white.opacity(0.2))
                        .frame(width: 3, height: 6 + CGFloat(i) * 3)
                }
            }
            .frame(height: 12, alignment: .bottom)
            Text(difficulty.rawValue.capitalized)
                .font(.spaceGroteskBold(size: 11))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }

    private var level: Int {
        Difficulty.allCases.firstIndex(of: difficulty) ?? 0
    }
}

#Preview {
    ExercisePickerView { _ in }
}
