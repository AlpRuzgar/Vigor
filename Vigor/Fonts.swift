//
//  Fonts.swift
//  Vigor
//
//  Created by Alp Rüzgar on 5.10.2026.
//

import SwiftUI

extension Font {
    static func plusJakartaSans(size: CGFloat) -> Font {
        return Font.custom("PlusJakartaSans-Regular", size: size)
    }

    static func plusJakartaSansLight(size: CGFloat) -> Font {
        return Font.custom("PlusJakartaSans-Light", size: size)
    }

    static func plusJakartaSansSemiBold(size: CGFloat) -> Font {
        return Font.custom("PlusJakartaSans-SemiBold", size: size)
    }

    static func plusJakartaSansBold(size: CGFloat) -> Font {
        return Font.custom("PlusJakartaSans-Bold", size: size)
    }

    static func plusJakartaSansItalic(size: CGFloat) -> Font {
        return Font.custom("PlusJakartaSans-Italic", size: size)
    }

    static func spaceGrotesk(size: CGFloat) -> Font {
        return Font.custom("SpaceGrotesk-Regular", size: size)
    }

    static func spaceGroteskLight(size: CGFloat) -> Font {
        return Font.custom("SpaceGrotesk-Light", size: size)
    }

    static func spaceGroteskSemiBold(size: CGFloat) -> Font {
        return Font.custom("SpaceGrotesk-SemiBold", size: size)
    }

    static func spaceGroteskBold(size: CGFloat) -> Font {
        return Font.custom("SpaceGrotesk-Bold", size: size)
    }
}
