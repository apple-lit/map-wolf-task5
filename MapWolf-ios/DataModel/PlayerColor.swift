//
//  PlayerColor.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/22.
//

import SwiftUI
import UIKit

struct PlayerColor: Codable, Hashable, Equatable {
    let hex: String

    var color: UIColor {
        UIColor(hex: hex)
    }

    static let red = PlayerColor(hex: "#FF0000")
    static let blue = PlayerColor(hex: "#00FF00")
    static let green = PlayerColor(hex: "#0000FF")
}
