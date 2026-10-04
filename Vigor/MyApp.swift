import SwiftUI
import SwiftData

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(for: [ExerciseType.self, Workout.self,
                        WorkoutEntry.self, ExerciseSet.self])
    }
}
