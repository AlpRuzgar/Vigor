import SwiftUI
import Playgrounds

struct MainView: View {
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
    }
}

#Preview {
    MainView()
}
