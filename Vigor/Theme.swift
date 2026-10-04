//
//  Theme.swift
//  Vigor
//
//  Created by Alp Rüzgar on 3.10.2026.
//

import SwiftUI

extension View {
    func neonCard(_ color: Color, bgColor: Color, cornerRadius: CGFloat = 15) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(bgColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(color, lineWidth: 3)
                    .neonShadow(color)
            }
    }
    
    func neonShadow(_ color: Color) -> some View {
        self
            .shadow(color: color, radius: 4)
            .shadow(color: color.opacity(0.6), radius: 10)
    }
}

struct NeonButtonStyle: ButtonStyle {
    var foregroundColor: Color
    var bgColor: Color
    var width: CGFloat?
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: width ?? 100, height: 50)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .neonShadow(bgColor)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed)
    }
}

extension ButtonStyle where Self == NeonButtonStyle {
    static func neon(_ color: Color, bgColor: Color) -> NeonButtonStyle {
        NeonButtonStyle(foregroundColor: color, bgColor: bgColor)
    }
}
