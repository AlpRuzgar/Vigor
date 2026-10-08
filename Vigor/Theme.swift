//
//  Theme.swift
//  Vigor
//
//  Created by Alp Rüzgar on 3.10.2026.
//

import SwiftUI

extension View {
    func card(cornerRadius: CGFloat = 15, brightness: CGFloat = 0.1) -> some View {
        self
            .background(.coldBlack.mix(with: .white, by: brightness))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    func neonShadow(_ color: Color) -> some View {
        self
            .shadow(color: color, radius: 4)
            .shadow(color: color.opacity(0.6), radius: 10)
    }
}

struct NeonButtonStyle: ButtonStyle {
    var foregroundColor: Color
    var backgroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundStyle(foregroundColor)
            .font(.spaceGroteskBold(size: 20))
            .background(backgroundColor)
            .clipShape(Capsule())
            .neonShadow(backgroundColor)
    }
}

extension ButtonStyle where Self == NeonButtonStyle {
    static func neon(foregroundColor: Color, backgroundColor: Color) -> NeonButtonStyle {
        NeonButtonStyle(foregroundColor: foregroundColor, backgroundColor: backgroundColor)
    }
}

struct CustomStepper: View {
    var type: TargetType
    var isFree: Bool {
        type == .free
    }
    @Binding var value: Double
    var body: some View {
        VStack (spacing: 20) {
            HStack {
                StepperButton(symbol: "minus") {
                    value -= type.step
                }
                .disabled(value <= type.range.lowerBound || isFree)
                Spacer()
                Text(isFree ? "Free" : "\(value.formatted(.number.precision(.fractionLength(type == .distance ? 1: 0))))")
                    .font(.plusJakartaSansBold(size: 30))
                    .foregroundStyle(.white)
                Text(type.unit)
                    .font(.spaceGrotesk(size: 18))
                    .foregroundStyle(.electricLime)
                Spacer()
                StepperButton(symbol: "plus") {
                    value += type.step
                }
                .disabled(value >= type.range.upperBound || isFree)
            }
            .background(.coldBlack.mix(with: .white, by: 0.2))
            .clipShape(Capsule())
        }
    }
}

struct StepperButton: View {
    let symbol: String
    let action: () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: symbol)
                .font(.spaceGroteskBold(size: 24))
        }
        .frame(width: 60, height: 60)
        .foregroundStyle(.coldBlack)
        .background(.electricLime)
    }
} 
