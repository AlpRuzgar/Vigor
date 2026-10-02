//
//  User.swift
//  MyApp
//
//  Created by Alp Rüzgar on 1.10.2026.
//

import Foundation

enum Avatar {
    case bear
    case rabbit
    case deer
    
    var title: String {
        switch self {
        case .bear:
            "Bear"
        case .rabbit:
            "Rabbit"
        case .deer:
            "Deer"
        }
    }
    
    //TODO: resimleri ekle
}

enum Sex {
    case male
    case female
    case unspecified
}

struct User: Identifiable {
    var id = UUID()
    var avatar: Avatar
    var name: String
    var bday: Date
    var sex: Sex
    var weight: Measurement<UnitMass>
    var height: Measurement<UnitLength>
    
    var cardios: [CardioExercise]
    var workouts: [Workout]
    
    //TODO: profil statları için yeni değerler e. total distance ran
}
