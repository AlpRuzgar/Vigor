//
//  TemplateListView.swift
//  Vigor
//
//  Created by Alp Rüzgar on 21.10.2026.
//

import SwiftUI
import SwiftData

/// Kayıtlı şablonları listeler; bir satıra dokunulunca o şablonla antrenman başlatma butonu açılır.
/// Kendi ScrollView'u yoktur, kaydırılabilir bir ekranın içine yerleştirilmek üzere tasarlanmıştır.
struct TemplateListView: View {
    @Environment(TemplateManager.self) private var templateManager
    // Son kullanılanlar önce; hiç kullanılmamışlar oluşturulma tarihine göre sonda
    @Query(sort: [SortDescriptor(\WorkoutTemplate.lastUsed, order: .reverse),
                  SortDescriptor(\WorkoutTemplate.createdAt, order: .reverse)])
    private var templates: [WorkoutTemplate]
    @State private var selectedTemplate: WorkoutTemplate?
    var onStart: (WorkoutTemplate) -> Void

    var body: some View {
        LazyVStack(spacing: 12) {
            Text("Templates")
                .font(.plusJakartaSans(size: 16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            if templates.isEmpty {
                Text("Save a finished workout as a template to quick start it here.")
                    .font(.plusJakartaSans(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .card()
            } else {
                ForEach(templates) { template in
                    TemplateRow(template: template, isSelected: selectedTemplate == template) {
                        onStart(template)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedTemplate = selectedTemplate == template ? nil : template
                        }
                    }
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            delete(template)
                        }
                    }
                    .contextMenu {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            delete(template)
                        }
                    }
                }
            }
        }
        .swipeActionsContainerIfAvailable()
    }

    // Şablonun egzersizleri ve setleri cascade kuralıyla birlikte silinir
    private func delete(_ template: WorkoutTemplate) {
        withAnimation {
            if selectedTemplate == template { selectedTemplate = nil }
            templateManager.deleteTemplate(template)
        }
    }
}

struct TemplateRow: View {
    let template: WorkoutTemplate
    let isSelected: Bool
    let onStart: () -> Void

    // Kütüphaneden silinmiş egzersizler antrenmana eklenmeyeceği için sayılmaz
    private var validEntries: [TemplateEntry] {
        template.entries
            .filter { $0.exercise != nil }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    private var setCount: Int {
        validEntries.reduce(0) { $0 + $1.sets.count }
    }

    // Egzersiz sırasına göre tekrarsız hedef kaslar
    private var muscles: [TargetMuscle] {
        var seen = Set<TargetMuscle>()
        return validEntries
            .flatMap { $0.exercise?.targetMuscles ?? [] }
            .filter { seen.insert($0).inserted }
    }

    private var lastUsedString: String {
        guard let lastUsed = template.lastUsed else { return "Never used" }
        return "Last used \(lastUsed.formatted(.relative(presentation: .named)))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.electricLime)
                    .frame(width: 44, height: 44)
                    .background(.electricLime.opacity(0.15))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.plusJakartaSansBold(size: 16))
                        .foregroundStyle(.white)
                    Text(lastUsedString)
                        .font(.spaceGrotesk(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundStyle(.electricLime)
                    .rotationEffect(.degrees(isSelected ? 180 : 0))
            }

            HStack(spacing: 8) {
                WorkoutStat(value: "\(validEntries.count)", label: "Exercises")
                WorkoutStat(value: "\(setCount)", label: "Sets")
            }

            if !muscles.isEmpty {
                HStack(spacing: 6) {
                    ForEach(muscles.prefix(3), id: \.self) { muscle in
                        MuscleTag(text: muscle.displayName)
                    }
                    if muscles.count > 3 {
                        MuscleTag(text: "+\(muscles.count - 3)")
                    }
                }
            }

            if isSelected {
                Button("Start Workout", systemImage: "play.fill", action: onStart)
                    .buttonStyle(.neon(foregroundColor: .coldBlack, backgroundColor: .electricLime, fontSize: 16))
                    .disabled(validEntries.isEmpty)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .card()
    }
}

#Preview {
    let container = try! ModelContainer(for: WorkoutTemplate.self, TemplateEntry.self, TemplateSet.self,
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let bench = ExerciseType(name: "Bench Press", targetMuscles: [.chest, .triceps], difficulty: .hard)
    let template = WorkoutTemplate(name: "Push Day")
    container.mainContext.insert(template)
    let entry = TemplateEntry(orderIndex: 0, exercise: bench)
    entry.sets = [TemplateSet(orderIndex: 0, reps: 10, durationSeconds: nil, weightKg: 60)]
    template.entries = [entry]
    return ScrollView {
        TemplateListView { _ in }
            .padding()
    }
    .background(.coldBlack)
    .environment(TemplateManager(context: container.mainContext))
    .modelContainer(container)
}
