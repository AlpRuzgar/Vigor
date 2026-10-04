import SwiftUI
import SwiftData

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(for: [User.self, RunSession.self,
                              ExerciseType.self, Workout.self,
                              WorkoutEntry.self, ExerciseSet.self])
    }
}
