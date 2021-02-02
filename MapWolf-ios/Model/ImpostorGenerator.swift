//
//  ImpostorGenerator.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/26.
//

import Foundation

class ImpostorGenerator {
    func decideImpostorIndexes(from room: Room, players: [Player]) -> [Int] {
        var indexes: [Int] = []
        let impostorCount = room.impostorCount
        let playerCount = players.count
        if impostorCount <= 1 {
            indexes.append(players.indices.randomElement()!)
        } else {
            let range = (0..<playerCount - 1).shuffled()
            for i in (0..<impostorCount) {
                indexes.append(range[i])
            }
        }
        return indexes
    }
}
