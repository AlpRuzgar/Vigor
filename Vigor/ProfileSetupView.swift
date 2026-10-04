//
//  ProfileSetupView.swift
//  Vigor
//
//  Created by Alp Rüzgar on 4.10.2026.
//

import SwiftUI
import SwiftData

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var avatar: Avatar = .bear
    @State private var bday = Calendar.current.date(byAdding: .year, value: -20, to: .now) ?? .now
    @State private var sex: Sex = .unspecified
    @State private var weightKg: Double = 70
    @State private var heightCm: Double = 170

    var body: some View {
        NavigationStack {
            Form {
                Section("Profil") {
                    TextField("İsim", text: $name)
                    Picker("Avatar", selection: $avatar) {
                        ForEach(Avatar.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                }

                Section("Bilgiler") {
                    DatePicker("Doğum tarihi", selection: $bday, in: ...Date.now, displayedComponents: .date)
                    Picker("Cinsiyet", selection: $sex) {
                        ForEach(Sex.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                    }
                    HStack {
                        Text("Kilo (kg)")
                        TextField("", value: $weightKg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Boy (cm)")
                        TextField("", value: $heightCm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Button("Kaydet", action: save)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .navigationTitle("Hoş geldin")
        }
    }

    private func save() {
        let user = User(avatar: avatar, name: name, bday: bday, sex: sex,
                        weightKg: weightKg, heightCm: heightCm)
        modelContext.insert(user)
    }
}
