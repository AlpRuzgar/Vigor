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
                    ListNavLink(destination: CardioListView() , label: "Cardios", icon: "waveform.path.ecg")
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

struct CardioListView: View {
    @Query(sort: \CardioSession.date, order: .reverse)
    private var sessions: [CardioSession]
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if sessions.isEmpty {
                    ContentUnavailableView{
                        Label("You haven't done any cardio exercises yet!", systemImage: "xmark.circle")
                            .foregroundStyle(.voltRed)
                            .font(.spaceGrotesk(size: 24))
                    }
                    .card()
                } else {
                    ForEach(sessions) { session in
                        NavigationLink {
                            ScrollView {
                                CardioDetailsView(cardioSession: session)
                                    .padding()
                            }
                            .background(.coldBlack)
                        } label: {
                            CardioSessionRow(session: session)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(.coldBlack)
        .navigationBarTitleDisplayMode(.inline)
        .customToolbar(title: "Cardios")
    }
}

struct CardioSessionRow: View {
    let session: CardioSession
    var body: some View {
        HStack {
            Image(systemName: session.activity.systemImage)
                .font(.system(size: 24))
                .foregroundStyle(.electricLime)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(session.activity.title)
                    .font(.plusJakartaSansBold(size: 16))
                    .foregroundStyle(.white)
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.spaceGrotesk(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Text(session.distance.formatted(.measurement(width: .abbreviated, usage: .road)))
                .font(.spaceGroteskBold(size: 16))
                .foregroundStyle(.electricLime)
        }
        .padding()
        .card()
    }
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
