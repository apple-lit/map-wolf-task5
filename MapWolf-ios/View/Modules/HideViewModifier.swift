//
//  HideViewModifier.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/30.
//

import SwiftUI

struct HideViewModifier: ViewModifier {
    let isHidden: Bool

    func body(content: Content) -> some View {
        if isHidden {
            return AnyView(content.hidden())
        } else {
            return AnyView(content)
        }
    }
}
