//
//  WeatherManager.swift
//  Vigor
//
//  Created by Alp Rüzgar on 5.10.2026.
//

import WeatherKit
import CoreLocation
import Combine

@MainActor
class WeatherManager: ObservableObject {
    // Arayüzde güncellenecek veriler
    @Published var currentWeather: CurrentWeather?
    @Published var hourlyForecast: [HourWeather] = []
    @Published var errorMessage: String?
    
    private let weatherService = WeatherService.shared
    
    func fetchWeather(for location: CLLocation) async {
        do {
            // WeatherKit üzerinden tüm hava durumu verilerini tek bir istekte çekiyoruz
            let weather = try await weatherService.weather(for: location)
            
            // 1. Şu anki hava durumu
            self.currentWeather = weather.currentWeather
            
            // 2. Gelecek 24 saatlik tahmin
            let now = Date()
            let calendar = Calendar.current
            // Bulunduğumuz saatten itibaren 24 saat sonrasını hesaplıyoruz
            guard let twentyFourHoursFromNow = calendar.date(byAdding: .hour, value: 24, to: now) else { return }
            
            // Tüm saatlik tahminlerin içinden sadece önümüzdeki 24 saate ait olanları filtreliyoruz
            self.hourlyForecast = weather.hourlyForecast.filter { hour in
                hour.date >= now && hour.date <= twentyFourHoursFromNow
            }
            
        } catch {
            self.errorMessage = "Hava durumu verisi alınamadı: \(error.localizedDescription)"
        }
    }
}
