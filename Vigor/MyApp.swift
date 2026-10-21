import SwiftUI
import SwiftData

@main struct MyApp: App {
    let container: ModelContainer
    @State private var workoutTracker: WorkoutTracker

    init() {
        let container = try! ModelContainer(for: User.self, CardioSession.self,
                                            ExerciseType.self, Workout.self,
                                            WorkoutEntry.self, ExerciseSet.self)
        self.container = container
        ExerciseSeeder.seedIfNeeded(container.mainContext)
        let tracker = WorkoutTracker(context: container.mainContext)
        tracker.restoreUnfinished()
        _workoutTracker = State(initialValue: tracker)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(workoutTracker)
        }
        .modelContainer(container)
    }
}
