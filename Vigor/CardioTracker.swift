//
//  RunningViewModel.swift
//  Vigor
//
//  Created by Alp Rüzgar on 2.10.2026.
//

import Foundation
import MapKit

enum CardioState {
    case idle, active, paused, ended
}


@MainActor
@Observable
final class CardioTracker {
    private(set) var locations: [CLLocation] = []
    private(set) var distance: CLLocationDistance = 0 //Metre
    private(set) var startDate: Date?
    private(set) var endDate: Date?
    private(set) var state: CardioState = .idle
    
    private var pausedDuration: TimeInterval = 0
    private var pauseStart: Date?
    private var needsNewReference = false
    
    private(set) var laps: [Lap] = []
    private var lapStartDistance: CLLocationDistance = 0
    private var lapStartTime: TimeInterval = 0   // koşu süresi (duraklama hariç)
    
    private(set) var activity: CardioActivity = .running
        
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
        guard state == .idle || state == .ended else { return }
        self.activity = activity
        locations = []
        distance = 0
        pausedDuration = 0
        pauseStart = nil
        needsNewReference = false
        endDate = nil
        startDate = .now
        state = .active
        lm.startUpdatingLocation()
        laps = []
        lapStartDistance = 0
        lapStartTime = 0
    }

    func pause() {
        guard state == .active else { return }
        pauseStart = .now
        state = .paused
        lm.stopUpdatingLocation()
    }

    func resume() {
        guard state == .paused, let pauseStart else { return }
        pausedDuration += Date.now.timeIntervalSince(pauseStart)
        self.pauseStart = nil
        needsNewReference = true // devam eden ilk nokta mesafeye eklenmesin
        state = .active
        lm.startUpdatingLocation()
    }
        
    func end() {
        guard state == .active || state == .paused else { return }
        endDate = pauseStart ?? .now
        state = .ended
        lm.stopUpdatingLocation()
        let remaining = distance - lapStartDistance
        if remaining > 0 {
            laps.append(Lap(index: laps.count + 1,
                            distanceMeters: remaining,
                            duration: elapsed - lapStartTime))
        }
    }

    func handle(_ location: CLLocation) {
        guard state == .active, let startDate else { return }
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy<=20 else { return }  // Geçersiz ya da kötü doğruluklu nokta
        guard location.timestamp >= startDate else { return }   // Koşu başlamadan önceki (eski/önbellekteki) nokta

        if let last = locations.last, !needsNewReference {
            distance += location.distance(from: last)
        }
        needsNewReference = false
        locations.append(location)
        
        let moving = location.timestamp.timeIntervalSince(startDate) - pausedDuration
        if distance - lapStartDistance >= 1000 {
            laps.append(Lap(index: laps.count + 1,
                            distanceMeters: 1000,
                            duration: moving - lapStartTime))
            lapStartDistance += 1000
            lapStartTime = moving
        }
    }
    
    func makeSession() -> CardioSession? {
        guard let startDate, let endDate, !locations.isEmpty else { return nil }
        return CardioSession(
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
