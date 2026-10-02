//
//  RunningView.swift
//  MyApp
//
//  Created by Alp Rüzgar on 1.10.2026.
//

import SwiftUI
import MapKit

enum Stage {
    case idle
    case runStarted
    case runEnded
}

struct RunningView: View {
    @State private var lm = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var stage: Stage = .idle
    
    @State private var isExpanded = false
    @GestureState private var dragOffset: CGFloat = 0
    
    
    var body: some View {
        VStack{
            Map(position: $cameraPosition) {
                UserAnnotation()
            }
            .onAppear {
                if lm.authorizationStatus == .notDetermined {
                    lm.requestAuthorization()
                }
            }
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
            
        }
    }
    
    @ViewBuilder
    private func startingMenu() -> some View {
        Button("Start Run") {
            withAnimation {
                stage = .runStarted
            }
        }
    }
    
    @ViewBuilder
    private func runMenu() -> some View {
        VStack {
            Text("Run")
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
