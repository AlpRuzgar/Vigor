import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeView()
            }
            Tab("Run", systemImage: "figure.run") {
                RunningView()
            }
            Tab("Workout", systemImage: "dumbbell") {
                WorkoutView()
            }
            Tab("Profile", systemImage: "person") {
                ProfileView()
            }
        }
        .task { ExerciseSeeder.seedIfNeeded(modelContext) }
    }
}

#Preview {
    MainView()
}
