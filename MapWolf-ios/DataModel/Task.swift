//
//  Task.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/20.
//

import SwiftUI

struct SpotTask: Codable, Hashable {
    var id: Int
    var latitude: Double
    var longitude: Double
    var next: Int
    var preivous: Int
    var colorHex: String
    var isSabotaged: Bool = false
}

struct CooperateTask: Codable, Hashable {
    var id: Int
    var qr: String?
    var avatar: Avatar?
    var color: PlayerColor?
}
// dummy
let spotTasks: [SpotTask] = [
    //appleの前
    .init(
        id: 0, latitude: 35.66656, longitude: 139.71096, next: 1, preivous: -1,
        colorHex: UIColor.systemRed.hexString),  // -1はなし
    //あにべるせる表参道
    .init(
        id: 1, latitude: 35.6662163, longitude: 139.7113619, next: 2, preivous: 0,
        colorHex: UIColor.systemBlue.hexString),
    //moscafe
    .init(
        id: 2, latitude: 35.66662, longitude: 139.70994, next: 3, preivous: 1,
        colorHex: UIColor.systemGreen.hexString),
    //プリーズ青山
    .init(
        id: 3, latitude: 3_566_700, longitude: 139.71128, next: 4, preivous: 2,
        colorHex: UIColor.systemOrange.hexString),
    //サーフェス
    .init(
        id: 4, latitude: 35.6676011, longitude: 139.7102305, next: 5, preivous: 3,
        colorHex: UIColor.systemPink.hexString)
    //    .init(
    //        id: 5, latitude: 40, longitude: 130, next: 6, preivous: 4,
    //        colorHex: UIColor.systemPurple.hexString)
]

let taskLocationCandidates: [(lat: Double, long: Double)] = [
    (35.6809591, 139.7673070),
    (35.6809591, 139.7673070),
    (35.6809591, 139.7673070),
    (35.6809590, 139.7673069),
    (35.6809590, 139.7673069),
    (35.6809590, 139.7673069)
]
