//
//  Impostor.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/20.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Impostor: Player {
    static var collectionName: String = "players"
    static var identifier: String = "impostor"

    static var parentCollectionName: String = "rooms"

    @DocumentID
    var ref: DocumentReference?
    var uid: String?
    var nickName: String
    var killedCrewmates: [Crewmate]
    var qrCode: String
    var avatar: Avatar
    var color: PlayerColor
    var role: PlayerRole = .impostor
    var location: PlayerLocation?
}
