//
//  ProfileView.swift
//  MyApp
//
//  Created by Alp Rüzgar on 1.10.2026.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Edit Profile") {
                    EditProfileView()
                }
            }
            .navigationTitle("Profile")
        }
    }
}
#Preview {
    ProfileView()
}
