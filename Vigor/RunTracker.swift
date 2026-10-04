//
//  RunningViewModel.swift
//  Vigor
//
//  Created by Alp Rüzgar on 2.10.2026.
//

import Foundation
import MapKit

@MainActor
@Observable
final class RunTracker {
    private(set) var locations: [CLLocation] = []
    private(set) var distance: CLLocationDistance = 0 //Metre
    private(set) var startDate: Date?
    private(set) var endDate: Date?
    private(set) var isRunning = false
    
    let lm = LocationManager()
    
    init() {
        lm.onNewLocation = { [weak self] location in
            Task { @MainActor in
                self?.handle(location)
            }
        }
    }
    
    // Geçen süre: bitmişse bitiş anına, değilse şu ana kadar
    var elapsed: TimeInterval {
        guard let startDate else { return 0 }
        return (endDate ?? .now).timeIntervalSince(startDate)
    }
    
    // Anlık pace: saniye/km. Yeterli veri yoksa nil.
    var currentPace: TimeInterval? {
        guard let last = locations.last else { return nil }

        // Son konum çok eskiyse (durduysan) pace gösterme
        guard Date.now.timeIntervalSince(last.timestamp) < 20 else { return nil }

        var covered: CLLocationDistance = 0
        var previous = last

        for location in locations.dropLast().reversed() {
            covered += previous.distance(from: location)
            previous = location

            if covered >= 100 {
                let seconds = last.timestamp.timeIntervalSince(location.timestamp)
                return seconds / (covered / 1000)
            }
        }
        return nil // henüz 100 m birikmedi
    }
    
    func start() {
        guard !isRunning else { return }
        locations = []
        distance = 0
        endDate = nil
        startDate = .now
        isRunning = true
        lm.startUpdatingLocation()
    }
        
    func end() {
        guard isRunning else { return }
        isRunning = false
        endDate = .now
        lm.stopUpdatingLocation()
    }
    
    func handle(_ location: CLLocation) {
        guard isRunning, let startDate else { return }
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy<=20 else { return }  // Geçersiz ya da kötü doğruluklu nokta
        guard location.timestamp >= startDate else { return }   // Koşu başlamadan önceki (eski/önbellekteki) nokta

        if let last = locations.last {
            distance += location.distance(from: last)
        }
        
        locations.append(location)
    }
    
    func makeSession() -> RunSession? {
        guard let startDate, let endDate, !locations.isEmpty else { return nil }
        return RunSession(
            date: startDate,
            distanceMeters: distance,
            duration: endDate.timeIntervalSince(startDate),
            points: locations.map { RoutePoint($0) }
        )
    }
}

extension RoutePoint {
    init(_ location: CLLocation)  {
        self.init(latitude: location.coordinate.latitude,
                  longitude: location.coordinate.longitude,
                  altitude: location.altitude,
                  timestamp: location.timestamp
        )
    }
}
