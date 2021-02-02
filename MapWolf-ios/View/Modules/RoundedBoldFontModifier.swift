//
//  RoundedBoldFontModifier.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/24.
//

import SwiftUI

struct RoundedBoldFontModifier: ViewModifier {
    let fontSize: CGFloat

    func body(content: Content) -> some View {
        content.font(.system(size: fontSize, weight: .bold, design: .rounded))
    }
}
