//
//  ProfileView.swift
//  MyApp
//
//  Created by Alp Rüzgar on 1.10.2026.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(User.self) private var user
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack (spacing: 20){
                    profileDetailBar()
                    allTimeStatsCard()
                    ListNavLink(destination: CardioListView() , label: "All Cardios", icon: "waveform.path.ecg")
                    ListNavLink(destination: WorkoutListView(), label: "All Workouts", icon: "dumbbell")
                }
                .padding()
            }
            .background(.coldBlack)
            .navigationBarTitleDisplayMode(.inline)
            .customToolbar(title: "Profile")
        }
    }

    @ViewBuilder
    private func profileDetailBar() -> some View {
        HStack {
            user.avatar.image
            VStack (spacing: 12){
                Text(user.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.plusJakartaSansBold(size: 42))
                    .foregroundStyle(.electricLime)
                HStack(spacing: 5){
                    Text("Joined at:")
                        .font(.spaceGrotesk(size: 14))
                        .foregroundStyle(.electricLime)

                    Text(user.joinedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.spaceGroteskBold(size: 18))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .card()
    }
    
    @ViewBuilder
    private func allTimeStatsCard() -> some View {
        
    }
}
#Preview {
    ProfileView()
        .environment(User.preview)
}


struct ListNavLink<Destination: View>: View {
    var destination: Destination
    var label: String
    var icon: String?
    var body: some View {
        NavigationLink (destination: destination ) {
            HStack{
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(.electricLime)
                }
                Text(label)
                    .font(.plusJakartaSansBold(size: 16))
                    .foregroundStyle(.electricLime)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.electricLime)
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .card()
    }
}
