//
//  Avatar.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/22.
//

import UIKit

struct Avatar: Codable, Equatable, Hashable {
    let resourceName: String

    static let defaultAvatar: Avatar = .init(resourceName: "🐷")
}
