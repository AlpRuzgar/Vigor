//
//  RunningView.swift
//  MyApp
//
//  Created by Alp Rüzgar on 1.10.2026.
//

import SwiftUI
import MapKit
import SwiftData

enum Stage {
    case idle
    case runStarted
    case runEnded
}

struct RunningView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var stage: Stage = .idle
    @State private var showEndConfirmation = false
    @State private var tracker = RunTracker()
    
    private var elapsedString: String {
        let minutes = Int(tracker.elapsed) / 60
        let seconds = Int(tracker.elapsed) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var distanceString: String {
        Measurement(value: tracker.distance, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
    }

    private var paceString: String {
        guard let pace = tracker.currentPace, pace < 1800 else { return "--:-- /km" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
        
    var body: some View {
        ScrollView {
            VStack (spacing: 20){
                Text("Cardio")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Map(position: $cameraPosition) {
                    UserAnnotation()
                    if tracker.locations.count > 1 {
                        MapPolyline(coordinates: tracker.locations.map(\.coordinate))
                            .stroke(.blue, lineWidth: 5)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .onAppear {
                    if tracker.lm.authorizationStatus == .notDetermined {
                        tracker.lm.requestAuthorization()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 15))
                
                VStack {
                    switch stage {
                    case .idle:
                        startingMenu()
                    case .runStarted:
                        runMenu()
                    case .runEnded:
                        endingMenu()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .scrollClipDisabled()
    }
    
    
    @ViewBuilder
    private func startingMenu() -> some View {
        VStack {
            Button("Start Run") {
                tracker.start()
                withAnimation(.spring) {
                    stage = .runStarted
                }
            }
        }
        
    }
    
    @ViewBuilder
    private func runMenu() -> some View {
        VStack(spacing: 20) {
            InfoCard(title: "Distance", value: distanceString, color: .primaryPink)
            HStack(spacing: 12){
                // Her saniye içeriği yeniden hesaplatır
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    InfoCard(title: "Time", value: elapsedString, color: .primaryPink)
                }
                InfoCard(title: "Pace", value: paceString, color: .tertiaryYellow)
            }
            

            Button("End") {
                showEndConfirmation = true
            }
            .buttonStyle(.neon(.white, bgColor: .primaryPink))
            .confirmationDialog("Koşuyu bitirmek istiyor musun?",
                                isPresented: $showEndConfirmation,
                                titleVisibility: .visible) {
                Button("End", role: .destructive) {
                    tracker.end()
                    if let session = tracker.makeSession() {
                        modelContext.insert(session)
                    }
                    withAnimation {
                        stage = .runEnded
                    }
                }
                Button("Continue", role: .cancel) { }
            }
        }
    }

    @ViewBuilder
    private func endingMenu() -> some View {
        VStack {
            Text("End")
        }
    }
    
}

//TODO: use stitch for ui design

#Preview {
    RunningView()
}

extension View {
    func infoCard(_ color: Color, bgColor: Color, height: CGFloat) -> some View {
        self
            .frame(height: height)
            .neonCard(color, bgColor: bgColor)
    }
}

struct InfoCard: View {
    var title: String
    var value: String
    var color: Color
    var height: CGFloat?
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(title): ")
                .font(.footnote)
                .foregroundStyle(.white)
                .bold()
            Text(value)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .infoCard(color, bgColor: .navyBlue, height: height ?? 90)
    }
}
