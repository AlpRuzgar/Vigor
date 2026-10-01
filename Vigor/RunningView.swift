//
//  RunningView.swift
//  MyApp
//
//  Created by Alp Rüzgar on 1.10.2026.
//

import SwiftUI
import MapKit

struct RunningView: View {
    @State private var lm = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
        }
        .onAppear {
            if lm.authorizationStatus == .notDetermined {
                lm.requestAuthorization()
            }
        }
    }
    
}

//TODO: use stitch for ui design

#Preview {
    RunningView()
}
