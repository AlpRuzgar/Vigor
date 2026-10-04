//
//  User.swift
//  MyApp
//
//  Created by Alp Rüzgar on 1.10.2026.
//

import Foundation
import SwiftData

enum Avatar: String, Codable, CaseIterable {
    case bear, rabbit, deer

    var title: String {
        switch self {
        case .bear: "Bear"
        case .rabbit: "Rabbit"
        case .deer: "Deer"
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

    var weight: Measurement<UnitMass> { .init(value: weightKg, unit: .kilograms) }
    var height: Measurement<UnitLength> { .init(value: heightCm, unit: .centimeters) }

    init(avatar: Avatar, name: String, bday: Date, sex: Sex, weightKg: Double, heightCm: Double) {
        self.avatar = avatar
        self.name = name
        self.bday = bday
        self.sex = sex
        self.weightKg = weightKg
        self.heightCm = heightCm
    }
}
