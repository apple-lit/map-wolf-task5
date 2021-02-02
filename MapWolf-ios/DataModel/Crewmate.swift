//
//  Crewmate.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/20.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Crewmate: Player {
    static var collectionName: String = "players"
    static var identifier: String = "crewmate"

    static var parentCollectionName: String = "rooms"

    @DocumentID
    var ref: DocumentReference?
    var uid: String?
    var nickName: String
    var spotTasks: [SpotTask]
    var cooperateTasks: [CooperateTask]
    var completeCooperateTaskIDList: [Int]
    var completeSpotTaskIDList: [Int]
    var qrCode: String
    var avatar: Avatar
    var color: PlayerColor
    var role: PlayerRole = .crewmate
    var location: PlayerLocation?
    var isSabotaged: Bool

    var isComplete: Bool {
        completeSpotTaskIDList.count == spotTasks.count
            && completeCooperateTaskIDList.count == cooperateTasks.count
    }
}
