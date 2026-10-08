//
//  ForecastView.swift
//  Vigor
//
//  Created by Alp Rüzgar on 5.10.2026.
//

import SwiftUI
import WeatherKit
import CoreLocation
import Combine

struct ForecastView: View {
    var location: CLLocation?
    @StateObject private var weatherManager = WeatherManager()
    var body: some View {
        VStack {
            if let current = weatherManager.currentWeather {
                let hourly = weatherManager.hourlyForecast
                VStack (spacing: 20){
                    HStack {
                        HStack {
                            Image(systemName: current.symbolName)
                                .font(.system(size: 40))
                                .symbolVariant(.fill)
                                .symbolRenderingMode(.multicolor)
                                .padding(8)
                                .card(brightness: 0.2)
                            VStack {
                                Text("\(current.temperature.formatted(.measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(0)))))")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.spaceGroteskBold(size: 36))
                                    .foregroundStyle(.white)
                                Text(current.condition.description)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.plusJakartaSans(size: 14))
                                    .foregroundStyle(.white)
                                
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            VStack (spacing: 12){
                                Text("Feels like \(current.apparentTemperature.formatted(.measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(0)))))")
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .font(.plusJakartaSans(size: 14))
                                    .foregroundStyle(.white)
                                HStack {
                                    Text("Precipitation")
                                        .foregroundStyle(.white)
                                    Text("%\(hourly[0].precipitationChance.formatted())")
                                        .foregroundStyle(.neonBlue)
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .font(.plusJakartaSans(size: 14))
                            }
                        }
                    }
                    HStack {
                        WeatherDetailCard(icon: "wind", iconColor: .iceBlue, value: "\(current.wind.speed.formatted()) \(current.wind.compassDirection.shortenedAbbreviation)")
                        WeatherDetailCard(icon: "eye", iconColor: .electricLime, value: current.visibility.formatted())
                        WeatherDetailCard(icon: "sun.max", iconColor: .orange, value: "UV \(current.uvIndex.value.formatted())")
                        WeatherDetailCard(icon: "humidity", iconColor: .neonBlue, value: current.humidity.formatted(.percent))
                    }
                    ScrollView (.horizontal) {
                        HStack{
                            ForEach(hourly, id: \.date) { forecast in
                                HourlyForecastCard(hour: forecast.date.formatted(date: .omitted, time: .shortened),
                                                   icon: forecast.symbolName,
                                                   rainChance: forecast.precipitationChance.formatted(.percent),
                                                   temp: forecast.temperature.formatted(.measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(0)))))
                                
                            }
                        }
                    }
                }
            }
            else if let errorMessage = weatherManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.black)
            }
            else {
                ProgressView()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .card()
        .task(id: location) {
            guard let location else { return }
            await weatherManager.fetchWeather(for: location)
        }
    }
}

extension Wind.CompassDirection {
    /// Shortens the 16-point abbreviation (e.g. "ESE") down to the nearest
    /// of the 8 main compass points (e.g. "SE").
    var shortenedAbbreviation: String {
        switch self {
        case .north: return "N"
        case .northNortheast, .eastNortheast: return "NE"
        case .northeast: return "NE"
        case .eastSoutheast, .southSoutheast: return "SE"
        case .east: return "E"
        case .southeast: return "SE"
        case .south: return "S"
        case .southSouthwest, .westSouthwest: return "SW"
        case .southwest: return "SW"
        case .west: return "W"
        case .westNorthwest, .northNorthwest: return "NW"
        case .northwest: return "NW"
        @unknown default: return abbreviation
        }
    }
}

struct WeatherDetailCard: View {
    var icon: String
    var iconColor: Color = .white
    var value: String
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 30))
                .symbolVariant(.fill)
                .padding(.vertical, 8)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.spaceGroteskBold(size: 14))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .padding(.vertical, 8)
        .card(brightness: 0.2)
    }
}

struct HourlyForecastCard: View {
    var hour: String
    var icon: String
    var rainChance: String
    var temp: String
    
    var isRain: Bool {
        rainChance != "%0"
    }
    var body: some View {
        VStack(spacing: 8) {
            Text(hour)
                .font(.spaceGrotesk(size: 14))
                .foregroundStyle(.white)
            Image(systemName: icon)
                .symbolVariant(.fill)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 30))
                .frame(height: 40)
            Text( isRain ? rainChance : "")
                .foregroundStyle(.neonBlue)
                .frame(height: 20)
            Text(temp)
                .font(.spaceGroteskBold(size: 14))
                .foregroundStyle(.white)
        }
        .frame(width: 50,height: 120)
        .padding(8)
        .card(brightness: 0.2)
    }
}


#Preview {
    ForecastView(location: CLLocation(latitude: 41.0, longitude: 28.0))
}
