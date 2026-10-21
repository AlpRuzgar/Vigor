import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    var body: some View {
        Group {
            if let user = users.first {
                TabView {
                    Tab("Home", systemImage: "house") {
                        HomeView()
                    }
                    Tab("Run", systemImage: "figure.run") {
                        CardioView()
                    }
                    Tab("Workout", systemImage: "dumbbell") {
                        WorkoutView()
                    }
                    Tab("Profile", systemImage: "person") {
                        ProfileView()
                    }
                }
                .environment(user)
            }
            else {
                ProfileSetupView()
            }
        }
    }
}

#Preview {
    MainView()
}
