//
//  TaskGenerator.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/25.
//

import Foundation

class TaskGenerator {
    func configureTask(of crewmate: Crewmate, cooperates: [CooperateTask], spots: [SpotTask])
        -> Crewmate {
        var crewmate = crewmate
        crewmate.cooperateTasks = []
        crewmate.spotTasks = []
        let spots = spots.shuffled()
        let cooperates = cooperates.shuffled()
        for spot in spots {
            crewmate.spotTasks.append(spot)
        }
        for cooperate in cooperates {
            crewmate.cooperateTasks.append(cooperate)
        }
        return crewmate
    }

    func configureCooperateTasksAvatar(of me: Crewmate, players: [Player]) -> [CooperateTask] {
        let cooperates = players.filter { $0.uid != me.uid }.enumerated().map {
            CooperateTask(id: $0, qr: $1.uid, avatar: $1.avatar)
        }
        return cooperates
    }
}
