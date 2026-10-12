//
//  User.swift
//  MyApp
//
//  Created by Alp Rüzgar on 1.10.2026.
//

import Foundation
import SwiftData
import SwiftUI

enum Avatar: String, Codable, CaseIterable {
    case bear, rabbit, deer

    var title: String {
        switch self {
        case .bear: "Bear"
        case .rabbit: "Rabbit"
        case .deer: "Deer"
        }
    }
    
    var image: Image {
        switch self {
        case .bear:
            Image("")
        case .rabbit:
            Image("")
        case .deer:
            Image("")
        }
    }
}

enum Sex: String, Codable, CaseIterable {
    case male, female, unspecified
}

@Model
final class User {
    var avatar: Avatar
    var name: String
    var bday: Date
    var sex: Sex
    var weightKg: Double
    var heightCm: Double
    var joinedAt: Date

    var weight: Measurement<UnitMass> { .init(value: weightKg, unit: .kilograms) }
    var height: Measurement<UnitLength> { .init(value: heightCm, unit: .centimeters) }

    init(avatar: Avatar, name: String, bday: Date, sex: Sex, weightKg: Double, heightCm: Double, joinedAt: Date = .now) {
        self.avatar = avatar
        self.name = name
        self.bday = bday
        self.sex = sex
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.joinedAt = joinedAt
    }
}

extension User {
    // Preview'larda environment'a verilecek örnek kullanıcı
    static var preview: User {
        User(avatar: .bear, name: "Alp", bday: .now, sex: .male, weightKg: 70, heightCm: 175)
    }

    // MET formülü: kcal = MET × kilo(kg) × süre(saat)
    func calories(for activity: CardioActivity, duration: TimeInterval) -> Double {
        activity.met * weightKg * duration / 3600
    }
}
