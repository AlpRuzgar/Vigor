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
    
    /// ScrollView içindeki satırlarda kaydırma aksiyonlarını koordine eder (iOS 27+; öncesinde etkisiz)
    @ViewBuilder
    func swipeActionsContainerIfAvailable() -> some View {
        if #available(iOS 27.0, *) {
            self.swipeActionsContainer()
        } else {
            self
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
    var backgroundColor: Color
    var fontSize: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundStyle(foregroundColor)
            .font(.spaceGroteskBold(size: fontSize))
            .background(backgroundColor)
            .clipShape(Capsule())
            .neonShadow(backgroundColor)
    }
}

extension ButtonStyle where Self == NeonButtonStyle {
    static func neon(foregroundColor: Color, backgroundColor: Color, fontSize: CGFloat = 20) -> NeonButtonStyle {
        NeonButtonStyle(foregroundColor: foregroundColor, backgroundColor: backgroundColor, fontSize: fontSize)
    }
}

struct GoalStepper: View {
    var type: GoalType
    var isFree: Bool {
        type == .free
    }
    @Binding var value: Double
    var body: some View {
        VStack (spacing: 20) {
            HStack {
                StepperButton(symbol: "minus", foregroundColor: .white, backgroundColor: Color.regularGray) {
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
                StepperButton(symbol: "plus", foregroundColor: .white, backgroundColor: Color.regularGray) {
                    value += type.step
                }
                .disabled(value >= type.range.upperBound || isFree)
            }
            .background(Color.darkGray)
            .clipShape(Capsule())
        }
    }
}

struct StepperButton: View {
    var symbol: String
    var foregroundColor: Color = .coldBlack
    var backgroundColor: Color = .electricLime
    let action: () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: symbol)
                .font(.spaceGroteskBold(size: 24))
        }
        .frame(width: 60, height: 60)
        .foregroundStyle(foregroundColor)
        .background(backgroundColor)
    }
}

struct InfoCard: View {
    var title: String
    var icon: String
    var value: String
    var color: Color
    var isMain = false
    var goalText: String?
    var body: some View {
        VStack(alignment: isMain ? .center : .leading) {
            HStack {
                Text("\(title): ")
                    .font(.plusJakartaSans(size: 14))
                    .foregroundStyle(.white)
                if !isMain {
                    Spacer()
                    Image(systemName: icon)
                        .foregroundStyle(color)
                }
            }
            Text(value)
                .font(.spaceGroteskBold(size: isMain ? 36 : 24))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: isMain ? .center : .leading)
        .frame(height: 46)
        .padding()
        .card()
    }
}

extension Color {
    static let darkGray = Color.coldBlack.mix(with: .white, by: 0.1)
    static let regularGray = Color.coldBlack.mix(with: .white, by: 0.2)
    static let lightGray = Color.coldBlack.mix(with: .white, by: 0.3)
}
