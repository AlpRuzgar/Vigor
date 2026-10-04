//
//  EditProfileView.swift
//  Vigor
//
//  Created by Alp Rüzgar on 4.10.2026.
//

import SwiftUI
import SwiftData

struct EditProfileView: View {
    @Query private var users: [User]

    var body: some View {
        NavigationStack {
            if let user = users.first {
                ProfileForm(user: user)
                    .navigationTitle("Profil")
            }
        }
    }
}

#Preview {
    EditProfileView()
}

private struct ProfileForm: View {
    @Bindable var user: User

    var body: some View {
        Form {
            Section("Profil") {
                TextField("İsim", text: $user.name)
                Picker("Avatar", selection: $user.avatar) {
                    ForEach(Avatar.allCases, id: \.self) { Text($0.title).tag($0) }
                }
            }

            Section("Bilgiler") {
                DatePicker("Doğum tarihi", selection: $user.bday, in: ...Date.now, displayedComponents: .date)
                Picker("Cinsiyet", selection: $user.sex) {
                    ForEach(Sex.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                HStack {
                    Text("Kilo (kg)")
                    TextField("", value: $user.weightKg, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Boy (cm)")
                    TextField("", value: $user.heightCm, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }
}
