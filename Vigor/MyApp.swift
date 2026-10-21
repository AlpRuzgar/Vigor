import SwiftUI
import SwiftData

@main struct MyApp: App {
    let container: ModelContainer
    @State private var workoutTracker: WorkoutTracker
    @State private var templateManager: TemplateManager

    init() {
        let container = try! ModelContainer(for: User.self, CardioSession.self,
                                            Workout.self,
                                            WorkoutEntry.self, ExerciseSet.self,
                                            WorkoutTemplate.self, TemplateEntry.self,
                                            TemplateSet.self)
        self.container = container
        let tracker = WorkoutTracker(context: container.mainContext)
        tracker.restoreUnfinished()
        _workoutTracker = State(initialValue: tracker)
        _templateManager = State(initialValue: TemplateManager(context: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(workoutTracker)
                .environment(templateManager)
        }
        .modelContainer(container)
    }
}
