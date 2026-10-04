import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    var body: some View {
        Group {
            if users.first == nil {
                ProfileSetupView()
            }
            else {
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
            }
        }
        .task { ExerciseSeeder.seedIfNeeded(modelContext) }
    }
}

#Preview {
    MainView()
}
